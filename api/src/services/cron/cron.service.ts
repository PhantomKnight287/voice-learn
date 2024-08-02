import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { prisma } from 'src/db';
import { S3Service } from '../s3/s3.service';
import { ConfigService } from '@nestjs/config';
import { onesignal, PRODUCTS } from 'src/constants';
import { createId } from '@paralleldrive/cuid2';
import moment from 'moment-timezone';
import { IANATimezones } from 'src/constants/iana';
import { IAPService } from '@jeremybarbet/nest-iap';

@Injectable()
export class CronService {
  private readonly logger = new Logger(CronService.name);
  constructor(
    protected readonly s3: S3Service,
    protected readonly configService: ConfigService,
    private readonly iapService: IAPService,
  ) {}
  @Cron(CronExpression.EVERY_4_HOURS, {})
  async giveHeart() {
    const users = await prisma.user.findMany({
      where: {
        lives: {
          lt: 5,
        },
      },
    });
    await prisma.user.updateMany({
      where: {
        id: {
          in: users.map((user) => user.id),
        },
      },
      data: {
        lives: {
          increment: 1,
        },
      },
    });
  }

  @Cron(CronExpression.EVERY_DAY_AT_NOON, { timeZone: 'UTC' })
  async giveEmeraldsToProUsers() {
    const users = await prisma.user.findMany({ where: { tier: 'premium' } });
    const ids = users.map((u) => u.id);
    await prisma.user.updateMany({
      where: { id: { in: ids } },
      data: {
        emeralds: {
          increment: 100,
        },
      },
    });
  }
  @Cron(CronExpression.EVERY_5_MINUTES)
  async ensureAllGeneratedLessonsHaveQuestions() {
    const lessons = await prisma.lesson.findMany({
      where: { questionsStatus: 'generated', questions: { none: {} } },
    });
    const ids = lessons.map((l) => l.id);
    await prisma.lesson.updateMany({
      where: { id: { in: ids } },
      data: { questionsStatus: 'not_generated' },
    });
  }

  //   @Cron(CronExpression.EVERY_10_SECONDS)
  //   async pollSubscriptionStatus() {
  //     this.logger.debug('Polling subscription status for all users');

  //     const users = await prisma.user.findMany({
  //       where: { tier: 'premium' },
  //     });

  //     for (const user of users) {
  //       const transaction = await prisma.transaction.findFirst({
  //         where: {
  //           userId: user.id,
  //           type: 'subscription',
  //           platform: 'ios',
  //           purchaseId: { not: null },
  //         },
  //       });

  //       if (!transaction) continue;
  //       const now = Math.round(new Date().getTime() / 1000);
  //       const exp = now + 900
  //       const token = sign(
  //         {
  //           iat: now,
  //           iss: process.env.APPLE_ISSUER_ID,
  //           exp: exp,
  //           aud: 'appstoreconnect-v1',
  //           bid: 'com.voice-learn.app',
  //         },
  //         `-----BEGIN PRIVATE KEY-----
  // MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgwFEKCHOEqum4Xc/t
  // sg+aU9M1wv36wkMPsYkACjp1vWSgCgYIKoZIzj0DAQehRANCAATRXotBkyVzOBL+
  // mODQTKfS68M1IKHquIfp0P8rwYrNwkUYu/iwwakYvgN83nYDmdvaByo2sS2zcZZ7
  // aZfFP7//
  // -----END PRIVATE KEY-----`,
  //         {
  //           algorithm: 'ES256',
  //           header: {
  //             typ: 'JWT',
  //             kid: "4DUY38PY84",
  //             alg: 'ES256',
  //           },
  //         },
  //       );
  //       const data = await fetch(
  //         `${process.env.DEV === 'true'
  //           ? 'https://api.storekit-sandbox.itunes.apple.com/inApps/v1/subscriptions'
  //           : 'https://api.storekit.itunes.apple.com/inApps/v1/subscriptions'}/${transaction.purchaseId}`,
  //           {
  //             headers:{
  //               Authorization:`Bearer ${token}`
  //             }
  //           }
  //       );
  //       // const res = await  data.text()
  //       // console.log(res)
  //     }
  //   }

  @Cron(CronExpression.EVERY_MINUTE)
  async streakCronJob() {
    const users = await prisma.user.findMany();
    for (const user of users) {
      if (!user.timezone || !IANATimezones[user.timezone]) continue;
      const userLocalTime = moment().tz(IANATimezones[user.timezone]);
      if (userLocalTime.hour() === 0 && [0].includes(userLocalTime.minute())) {
        const lastStreakRecord = await prisma.streak.findFirst({
          where: { userId: user.id },
          orderBy: [{ createdAt: 'desc' }],
        });
        if (!lastStreakRecord) continue;

        const createdAt = moment(lastStreakRecord.createdAt).tz(
          IANATimezones[user.timezone],
        );
        const yesterdayStart = userLocalTime
          .clone()
          .subtract(1, 'day')
          .startOf('day');
        const yesterdayEnd = userLocalTime
          .clone()
          .subtract(1, 'day')
          .endOf('day');
        if (createdAt.isBetween(yesterdayStart, yesterdayEnd, null, '[]')) {
          if (user.notificationToken) {
            const res = await onesignal.createNotification({
              app_id: process.env.ONESIGNAL_APP_ID,
              name: 'Streak Safe Notification',
              contents: {
                en: 'Your streak is safe! Keep up the great work.',
              },
              headings: {
                en: 'Your streak is safe 😊',
              },
              include_subscription_ids: [user.notificationToken],
              large_icon:
                'https://cdn.voicelearn.tech/image-removebg-preview%20(1).png',
            });
          }
        } else {
          if (user.streakShields > 0) {
            await prisma.$transaction([
              prisma.user.update({
                where: { id: user.id },
                data: { streakShields: { decrement: 1 } },
              }),
              prisma.streak.create({
                data: {
                  id: `streak_${createId()}`,
                  type: 'shielded',
                  userId: user.id,
                  createdAt: yesterdayEnd.toDate(),
                },
              }),
            ]);
            if (user.notificationToken) {
              const res = await onesignal.createNotification({
                app_id: process.env.ONESIGNAL_APP_ID,
                name: 'Streak Shield Used Notification',
                contents: {
                  en: 'Your streak is safe thanks to the Streak Shield! Keep up the great work by completing a lesson today.',
                },
                headings: {
                  en: 'Your streak was saved by Streak Shield! 😊',
                },
                include_subscription_ids: [user.notificationToken],
                large_icon:
                  'https://cdn.voicelearn.tech/image-removebg-preview%20(1).png',
              });
            }
          } else {
            if (user.notificationToken) {
              await prisma.user.update({
                where: { id: user.id },
                data: { activeStreaks: 0 },
              });
              const res = await onesignal.createNotification({
                app_id: process.env.ONESIGNAL_APP_ID,
                name: 'Streak Reset Notification',
                headings: {
                  en: 'Your streak was reset 💀',
                },
                contents: {
                  en: 'Try not to skip more lessons.',
                },
                include_subscription_ids: [user.notificationToken],
                large_icon:
                  'https://cdn.voicelearn.tech/image-removebg-preview.png',
              });
            }
          }
        }
      } else if (
        (userLocalTime.hour() === 20 || userLocalTime.hour() == 22) &&
        userLocalTime.minute() === 0
      ) {
        const lastStreakRecord = await prisma.streak.findFirst({
          where: { userId: user.id },
          orderBy: [{ createdAt: 'desc' }],
        });
        if (!lastStreakRecord) continue;

        const createdAt = moment(lastStreakRecord.createdAt).tz(
          IANATimezones[user.timezone],
        );
        const isWithinRange = createdAt.isBetween(
          userLocalTime.clone().startOf('day'),
          userLocalTime,
          null,
          '[]',
        );
        if (isWithinRange) {
          return; // user already did a lesson for today
        } else {
          if (user.notificationToken)
            await onesignal.createNotification({
              app_id: process.env.ONESIGNAL_APP_ID,
              name: 'Streak Reminder',
              contents: {
                en: `Your streak is about to reset in ${userLocalTime.hour() == 20 ? '4' : '2'} hours. Complete a lesson now.`,
              },
              headings: {
                en: `⚠️ Streak about to reset`,
              },
              include_subscription_ids: [user.notificationToken],
              large_icon:
                'https://cdn.voicelearn.tech/image-removebg-preview.png',
            });
        }
      }
    }
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async completeIncompleteIOSTransactions() {
    const transactions = await prisma.transaction.findMany({
      where: {
        completed: false,
        platform: 'ios',
        userId: { not: null },
      },
    });
    for (const transaction of transactions) {
      const response = await this.iapService.verifyAppleReceipt({
        transactionReceipt: transaction.purchaseToken,
      });
      if (response.valid) {
        if (transaction.userId) {
          if (transaction.sku.startsWith('tier_')) {
            await prisma.user.update({
              where: { id: transaction.userId },
              data: {
                tier: 'premium',
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
            continue;
          } else {
            await prisma.user.update({
              where: {
                id: transaction.userId,
              },
              data: {
                emeralds: {
                  increment: PRODUCTS[transaction.sku] ?? 0,
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
          }
        }
      }
    }
  }
}
