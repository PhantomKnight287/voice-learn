import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import moment from 'moment';
import { prisma } from 'src/db';
import { S3Service } from '../s3/s3.service';
import { ConfigService } from '@nestjs/config';

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

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT, {
    timeZone: 'UTC',
  })
  async bonkLazyUsers() {
    console.log('Running cron for streaks');
    const currentDateInGMT = moment().utc().startOf('day').toDate(); // Start of the current day in GMT
    const nextDateInGMT = moment().utc().add(1, 'day').startOf('day').toDate(); // Start of the next day in GMT
    const users = await prisma.user.findMany();

    try {
      for (const user of users) {
        // Check if a streak record exists for today
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
          await prisma.user.update({
            where: { id: user.id },
            data: { activeStreaks: 0 },
          });
          console.log(`Active streaks reset for user: ${user.id}`);
        }
      }
    } catch (error) {
      console.error('Error resetting streaks:', error);
    }
  }
}
