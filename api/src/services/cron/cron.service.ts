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

  @Cron(CronExpression.EVERY_DAY_AT_10AM, { timeZone: 'UTC' })
  async notifyUsers() {
    const { currentDateInGMT, nextDateInGMT } = generateTimestamps();

    const users = await prisma.user.findMany({
      where: {
        notificationToken: { not: null },
      },
    });
    const ids = [];
    try {
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

      if (ids.length == 0) return;
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
    } catch (error) {
      console.error('Error resetting streaks:', error);
    }
  }

  @Cron(CronExpression.EVERY_DAY_AT_NOON, {
    timeZone: 'UTC',
  })
  async bonkLazyUsers() {
    const { currentDateInGMT, nextDateInGMT } = generateTimestamps();

    const users = await prisma.user.findMany();
    try {
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

        // If no streak record exists for today, reset activeStreaks to 0
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
              });
              console.log(res);
            }
          } else {
            await prisma.user.update({
              where: { id: user.id },
              data: { activeStreaks: 0 },
            });
            console.log(`Active streaks reset for user: ${user.id}`);
            if (user.notificationToken) {
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
              });
              console.log(res);
            }
          }
        }
      }
    } catch (error) {
      console.error('Error resetting streaks:', error);
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
