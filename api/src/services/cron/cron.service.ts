import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { prisma } from 'src/db';
import { S3Service } from '../s3/s3.service';
import { ConfigService } from '@nestjs/config';
import { generateTimestamps } from 'src/lib/time';
import { onesignal } from 'src/constants';
import { createId } from '@paralleldrive/cuid2';
import moment from 'moment-timezone';
import { IANATimezones } from 'src/constants/iana';

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
  //     include_subscription_ids:['a0bb338e-6cdd-46bf-83f7-f52bffc72cc6'],
  //   });
  //   console.log(res);
  // }

  @Cron(CronExpression.EVERY_SECOND)
  async streakCronJob() {
    const users = await prisma.user.findMany();
    for (const user of users) {
      if (!user.timezone || !IANATimezones[user.timezone]) return;
      const userLocalTime = moment().tz(IANATimezones[user.timezone]);
      if (
        userLocalTime.hour() === 0 &&
        [0, 1].includes(userLocalTime.minute())
      ) {
        const lastStreakRecord = await prisma.streak.findFirst({
          where: { userId: user.id },
          orderBy: [{ createdAt: 'desc' }],
        });
        if (!lastStreakRecord) return;

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
              });
            }
          }
        }
      }
    }
  }
}
