import { Injectable, Logger } from '@nestjs/common';
import { BUNDLE_ID, PRODUCTS } from 'src/constants';
import { prisma } from 'src/db';
import {
  decodeNotificationPayload,
  NotificationSubtype,
  NotificationType,
} from 'app-store-server-api';
import { Tiers } from '@prisma/client';
import { decode } from 'jsonwebtoken';

const SubscriptionType = {
  1: 'SUBSCRIPTION_RECOVERED',
  2: 'SUBSCRIPTION_RENEWED',
  3: 'SUBSCRIPTION_CANCELED',
  4: 'SUBSCRIPTION_PURCHASED',
  5: 'SUBSCRIPTION_ON_HOLD',
  6: 'SUBSCRIPTION_IN_GRACE_PERIOD',
  7: 'SUBSCRIPTION_RESTARTED',
  8: 'SUBSCRIPTION_PRICE_CHANGE_CONFIRMED',
  9: 'SUBSCRIPTION_DEFERRED',
  10: 'SUBSCRIPTION_PAUSED',
  11: 'SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED',
  12: 'SUBSCRIPTION_REVOKED',
  13: 'SUBSCRIPTION_EXPIRED',
} as const;

const InAppPurchaseType = {
  1: 'ONE_TIME_PRODUCT_PURCHASE',
  2: 'ONE_TIME_PRODUCT_CANCELED',
} as const;

interface Notification {
  version: string;
  notificationType: number;
  purchaseToken: string;
  subscriptionId: string;
}

interface GooglePlayNotification {
  message: {
    data: string;
    messageId: string;
    attributes: {
      [key: string]: string;
    };
  };
  subscription: string;
}

type DecodedData = {
  version: string;
  packageName: string;
  eventTimeMillis: string;
} & (
  | {
      subscriptionNotification: Notification;
      oneTimeProductNotification: null;
    }
  | {
      oneTimeProductNotification: Omit<
        Notification,
        'subscriptionId' | 'notificationType'
      > & {
        sku: keyof typeof PRODUCTS;
        notificationType: number;
      };
      subscriptionNotification: null;
    }
);

@Injectable()
export class WebhooksService {
  logger = new Logger(WebhooksService.name);
  async handleGooglePlayEvent(data: GooglePlayNotification) {
    const parsedData = JSON.parse(
      Buffer.from(data.message.data, 'base64').toString(),
    ) as DecodedData;

    if (
      !parsedData.oneTimeProductNotification &&
      !parsedData.subscriptionNotification
    )
      return;
    const transaction = await prisma.transaction.findFirst({
      where: {
        purchaseToken:
          parsedData.oneTimeProductNotification?.purchaseToken ||
          parsedData?.subscriptionNotification?.purchaseToken,
      },
    });

    if (parsedData.oneTimeProductNotification) {
      if (!transaction || !transaction.userId) {
        await prisma.transaction.create({
          data: {
            purchaseToken: parsedData.oneTimeProductNotification.purchaseToken,
            type: 'one_time_product',
            sku: parsedData.oneTimeProductNotification.sku,
            notificationType:
              parsedData.oneTimeProductNotification.notificationType,
            userUpdated: false,
          },
        });
        return;
      }
      if (transaction.userId) {
        await prisma.user.update({
          where: { id: transaction.userId },
          data: {
            emeralds: {
              [InAppPurchaseType[
                parsedData.oneTimeProductNotification
                  .notificationType as keyof typeof InAppPurchaseType
              ] === 'ONE_TIME_PRODUCT_CANCELED'
                ? 'decrement'
                : 'increment']:
                PRODUCTS[parsedData.oneTimeProductNotification.sku] ?? 0,
            },
            transactions: {
              update: {
                where: {
                  id: transaction.id,
                },
                data: { userUpdated: true, completed: true },
              },
            },
          },
        });
        return;
      }
    }

    const eventName: (typeof SubscriptionType)[keyof typeof SubscriptionType] =
      SubscriptionType[parsedData.subscriptionNotification.notificationType];
    if (
      eventName === 'SUBSCRIPTION_CANCELED' ||
      eventName === 'SUBSCRIPTION_EXPIRED' ||
      eventName === 'SUBSCRIPTION_REVOKED' ||
      eventName === 'SUBSCRIPTION_PAUSED'
    ) {
      try {
        const _transaction = await prisma.transaction.findFirst({
          where: {
            purchaseToken: parsedData.subscriptionNotification.purchaseToken,
          },
        });
        if (!_transaction) return;
        const transaction = await prisma.transaction.update({
          where: {
            id: _transaction.id,
          },
          data: {
            user: {
              update: {
                tier: 'free',
              },
            },
          },
        });
      } catch (e) {
        console.log(e);
      }
    } else if (
      eventName === 'SUBSCRIPTION_RESTARTED' ||
      eventName === 'SUBSCRIPTION_RECOVERED' ||
      eventName === 'SUBSCRIPTION_RENEWED'
    ) {
      try {
        const transaction = await prisma.transaction.findFirst({
          where: {
            purchaseToken: parsedData.subscriptionNotification.purchaseToken,
          },
        });
        if (!transaction) return;
        await prisma.transaction.update({
          where: {
            id: transaction.id,
          },
          data: {
            user: {
              update: {
                tier: 'premium',
              },
            },
          },
        });
      } catch (e) {
        console.log(
          'NO transaction with token found to renew, recover or restart',
        );
      }
    } else if (eventName === 'SUBSCRIPTION_PURCHASED') {
      if (!transaction || !transaction.userId) {
        await prisma.transaction.create({
          data: {
            purchaseToken: parsedData.subscriptionNotification.purchaseToken,
            type: 'subscription',
            sku: parsedData.subscriptionNotification.subscriptionId,
            notificationType:
              parsedData.subscriptionNotification.notificationType,
            userUpdated: false,
          },
        });
        return;
      }
      if (transaction.userId) {
        await prisma.user.update({
          where: { id: transaction.userId },
          data: {
            tier: {
              set: 'premium',
            },
            transactions: {
              update: {
                where: {
                  id: transaction.id,
                },
                data: { userUpdated: true, completed: true },
              },
            },
          },
        });
        return;
      }
    }
    return;
  }

  async handleAppStoreEvent(body: any) {
    const payload = await this.decodeNotificationPayload(body.signedPayload);

    if (payload.data.bundleId !== BUNDLE_ID.ios) {
      console.log('Notification not for this app');
      return;
    }

    const { notificationType, subtype } = payload;
    const data = this.extractTransactionData(payload);

    switch (notificationType) {
      case NotificationType.Subscribed:
        await this.handleSubscription(subtype, data);
        break;
      case NotificationType.Expired:
        await this.handleExpiration(data);
        break;
      case NotificationType.DidFailToRenew:
        await this.handleFailedRenewal(subtype, data);
        break;
      case NotificationType.Refund:
        await this.handleRefund(data);
        break;
      case NotificationType.ConsumptionRequest:
      case 'ONE_TIME_CHARGE':
        await this.handleConsumable(data);
        break;
      default:
        console.log(`Unhandled notification type: ${notificationType}`);
    }
  }

  private decodeNotificationPayload(signedPayload: string): any {
    try {
      return decode(signedPayload, { complete: true })?.payload;
    } catch (error) {
      console.error('Failed to decode signedPayload:', error);
      throw new Error('Invalid signedPayload');
    }
  }

  private extractTransactionData(payload: any): any {
    const transactionInfo = payload.data.signedTransactionInfo
      ? decode(payload.data.signedTransactionInfo, { complete: true })?.payload
      : {};
    return {
      //@ts-expect-error
      transactionId: transactionInfo.transactionId,
      //@ts-expect-error
      productId: transactionInfo.productId,
      //@ts-expect-error
      purchaseDate: transactionInfo.purchaseDate,
      ...payload.data,
    };
  }

  private async handleConsumable(data: any) {
    const transaction = await prisma.transaction.findFirst({
      where: { purchaseToken: data.transactionId },
      include: { user: true },
    });

    if (!transaction) {
      await this.createConsumableTransaction(data);
      return;
    }

    if (transaction.user) {
      await this.updateUserEmeralds(transaction, data);
    } else {
      console.log(`No user associated with transaction: ${transaction.id}`);
    }
  }

  private async createConsumableTransaction(data: any) {
    await prisma.transaction.create({
      data: {
        purchaseToken: data.transactionId,
        type: 'one_time_product',
        sku: data.productId,
        userUpdated: false,
      },
    });
  }

  private async updateUserEmeralds(transaction: any, data: any) {
    const purchaseType =
      InAppPurchaseType[data.type as keyof typeof InAppPurchaseType];
    const emeraldChange = PRODUCTS[data.productId] ?? 0;

    await prisma.user.update({
      where: { id: transaction.user.id },
      data: {
        emeralds: {
          [purchaseType === 'ONE_TIME_PRODUCT_CANCELED'
            ? 'decrement'
            : 'increment']: emeraldChange,
        },
        transactions: {
          update: {
            where: { id: transaction.id },
            data: { userUpdated: true, completed: true },
          },
        },
      },
    });
  }

  private async handleSubscription(subtype: NotificationSubtype, data: any) {
    switch (subtype) {
      case NotificationSubtype.InitialBuy:
      case NotificationSubtype.Resubscribe:
        await this.createOrUpdateTransaction(data, 'subscription', 'premium');
        break;
      default:
        console.log(`Unhandled subscription subtype: ${subtype}`);
    }
  }

  private async handleExpiration(data: any) {
    await this.updateTransactionAndUserTier(data, 'free');
  }

  private async handleFailedRenewal(subtype: NotificationSubtype, data: any) {
    if (subtype === NotificationSubtype.GracePeriod) {
      console.log(`User ${data.appAccountToken} entered grace period`);
    } else {
      await this.updateTransactionAndUserTier(data, 'free');
    }
  }

  private async handleRefund(data: any) {
    await this.updateTransactionAndUserTier(data, 'free');
  }

  private async createOrUpdateTransaction(
    data: any,
    type: 'subscription' | 'one_time_product',
    tier: string,
  ) {
    const transaction = await prisma.transaction.findFirst({
      where: { purchaseToken: data.transactionId },
    });

    if (!transaction) {
      await prisma.transaction.create({
        data: {
          purchaseToken: data.transactionId,
          type,
          sku: data.productId,
          userUpdated: false,
        },
      });
    } else {
      if (type === 'subscription') {
        await this.updateTransactionAndUserTier(data, tier);
      } else {
        await this.updateConsumableTransaction(transaction.id, data);
      }
    }
  }

  private async updateConsumableTransaction(transactionId: string, data: any) {
    await prisma.transaction.update({
      where: { id: transactionId },
      data: {
        userUpdated: true,
        completed: true,
      },
    });

    const transaction = await prisma.transaction.findUnique({
      where: { id: transactionId },
      include: { user: true },
    });

    if (transaction?.user) {
      await this.updateUserEmeralds(transaction, data);
    } else {
      console.log(`No user associated with transaction: ${transactionId}`);
    }
  }

  private async updateTransactionAndUserTier(data: any, tier: string) {
    const transaction = await prisma.transaction.findFirst({
      where: { purchaseToken: data.transactionId },
      include: { user: true },
    });

    if (!transaction) {
      console.log(
        `No transaction found for purchaseToken: ${data.transactionId}`,
      );
      return;
    }

    await prisma.transaction.update({
      where: { id: transaction.id },
      data: {
        userUpdated: true,
        completed: true,
      },
    });

    if (transaction.user) {
      await prisma.user.update({
        where: { id: transaction.user.id },
        data: { tier: tier as unknown as Tiers },
      });
    } else {
      console.log(`No user associated with transaction: ${transaction.id}`);
    }
  }

  async handleRevenueCatWebhook(data: any) {
    const userId = data.app_user_id;
    const user = await prisma.user.findFirst({
      where: {
        id: userId,
      },
    });
    if (!user?.id) return this.logger.error(`No user found with id: ${userId}`);
    if (data.type === 'INITIAL_PURCHASE') {
      // user bought premium, yayy!
      await prisma.user.update({
        data: { tier: 'premium' },
        where: { id: user.id },
      });
    } else if (data.type == 'RENEWAL') {
      // user renewed his subscription, yayy!
      await prisma.user.update({
        data: { tier: 'premium' },
        where: { id: user.id },
      });
    } else if (data.type === 'NON_RENEWING_PURCHASE') {
      // user bought emeralds
      await prisma.user.update({
        where: {
          id: user.id,
        },
        data: {
          emeralds: {
            increment: PRODUCTS[data.product_id] ?? 0,
          },
        },
      });
    } else if (data.type === 'EXPIRATION') {
      // subscription expired 😔
      await prisma.user.update({
        where: { id: user.id },
        data: { tier: 'free' },
      });
    }
  }
}
