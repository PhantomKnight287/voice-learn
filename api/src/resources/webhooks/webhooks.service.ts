import { Injectable } from '@nestjs/common';
import { PRODUCTS } from 'src/constants';
import { prisma } from 'src/db';

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
  async handleGooglePlayEvent(data: GooglePlayNotification) {
    const parsedData = JSON.parse(
      Buffer.from(data.message.data, 'base64').toString(),
    ) as DecodedData;

    if(!parsedData.oneTimeProductNotification && !parsedData.subscriptionNotification) return;
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
    console.log(eventName);
    return;
  }
}
