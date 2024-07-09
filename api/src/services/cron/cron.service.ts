import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import moment from 'moment';
import { prisma } from 'src/db';
import { S3Service } from '../s3/s3.service';
import { ConfigService } from '@nestjs/config';
import { generateTimestamps } from 'src/lib/time';
import { onesignal } from 'src/constants';
import { createId } from '@paralleldrive/cuid2';

@Injectable()
export class CronService {
  constructor(
    protected readonly s3: S3Service,
    protected readonly configService: ConfigService,
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

  @Cron('* 0/15 * * *')
  async notifyUsers() {
    const timeZoneOffsets = Array.from(
      { length: 24 * 4 },
      (_, i) => i * 15 - 720,
    ); // [-720, -705, ..., 705, 720]

    for (const offset of timeZoneOffsets) {
      const localTime = moment().utcOffset(offset);
      const localHour = localTime.hour();

      // Check if it's 10:00 AM in the user's local time
      if (localHour !== 10) continue;

      const { currentDateInGMT, nextDateInGMT } = generateTimestamps(offset);

      const users = await prisma.user.findMany({
        where: {
          notificationToken: { not: null },
          timeZoneOffSet: offset,
        },
      });

      const ids = [];
      for (const user of users) {
        // Check if a streak record exists between the timeframe
        const streakExists = await prisma.streak.findFirst({
          where: {
            userId: user.id,
            createdAt: {
              gte: currentDateInGMT,
              lt: nextDateInGMT,
            },
          },
        });

        if (!streakExists) {
          ids.push(user.notificationToken);
        }
      }

      if (ids.length == 0) continue;

      const res = await onesignal.createNotification({
        app_id: process.env.ONESIGNAL_APP_ID,
        name: 'Streak Notification',
        contents: {
          en: 'Your streak will reset in 2 hours. Complete a lesson now to extend it.',
        },
        headings: {
          en: 'Your streak is about to reset 😱😱',
        },
        include_subscription_ids: ids,
      });
      console.log(res);
    }
  }

  @Cron('* 0/15 * * *')
  async notifyLazyUsers() {
    const currentPhoneTime = new Date();
    const currentMinutes = currentPhoneTime.getUTCMinutes();
    const timeZoneOffsets = Array.from(
      { length: 24 * 4 },
      (_, i) => i * 15 - 720,
    ); // [-720, -705, ..., 705, 720]

    for (const offset of timeZoneOffsets) {
      if (currentMinutes % 15 !== 0) continue; // Ensure the cron only runs every 15 minutes

      const { currentDateInGMT, nextDateInGMT } = generateTimestamps(offset);

      const users = await prisma.user.findMany({
        where: {
          timeZoneOffSet: offset,
        },
      });

      for (const user of users) {
        // Check if a streak record exists between the timeframe
        const streakExists = await prisma.streak.findFirst({
          where: {
            userId: user.id,
            createdAt: {
              gte: currentDateInGMT,
              lt: nextDateInGMT,
            },
          },
        });

        if (!streakExists) {
          if (user.streakShields > 0) {
            await prisma.user.update({
              where: { id: user.id },
              data: {
                streakShields: { decrement: 1 },
                streaks: {
                  create: {
                    id: `streak_${createId()}`,
                    type: 'shielded',
                  },
                },
              },
            });

            if (user.notificationToken) {
              await onesignal.createNotification({
                app_id: process.env.ONESIGNAL_APP_ID,
                name: 'Streak Shield Used Notification',
                contents: {
                  en: 'Your streak is safe thanks to the Streak Shield! Keep up the great work by completing a lesson today.',
                },
                headings: {
                  en: 'Your streak was saved by Streak Shield! 😊',
                },
                include_subscription_ids: [user.notificationToken],
              });
            }
          } else {
            await prisma.user.update({
              where: { id: user.id },
              data: { activeStreaks: 0 },
            });

            if (user.notificationToken) {
              await onesignal.createNotification({
                app_id: process.env.ONESIGNAL_APP_ID,
                name: 'Streak Reset Notification',
                headings: {
                  en: 'Your streak was reset 💀',
                },
                contents: {
                  en: 'Try not to skip more lessons.',
                },
                include_subscription_ids: [user.notificationToken],
              });
            }
          }
        }
      }
    }
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

  // @Cron(CronExpression.EVERY_10_SECONDS, {
  //   disabled: process.env.DEV !== 'true',
  // })
  // async testNotifications() {
  //   console.log('sending notifications');
  //   const users = await prisma.user.findMany({
  //     where: { notificationToken: { not: null } },
  //   });
  //   const res = await onesignal.createNotification({
  //     app_id: process.env.ONESIGNAL_APP_ID,
  //     name: 'Test Notifications Using Cron',
  //     headings: {
  //       en: 'Your streak was reset 💀',
  //     },
  //     contents: {
  //       en: 'Try not to skip more lessons.',
  //     },
  //     include_subscription_ids: users.map((u) => u.notificationToken),
  //   });
  //   console.log(res);
  // }
}
