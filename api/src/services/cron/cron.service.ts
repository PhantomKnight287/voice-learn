import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import moment from 'moment';
import { prisma } from 'src/db';
import { S3Service } from '../s3/s3.service';
import { GetObjectCommand } from '@aws-sdk/client-s3';
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

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async refreshFlagsUrl() {
    const flags = await prisma.language.findMany({
      where: {
        flagUrlExpireTimestamp: {
          lte: moment().utc().startOf('day').toDate(),
        },
      },
    });
    for (const flag of flags) {
      const now = new Date();
      const oneWeekFromNow = new Date(now);

      const daysInOneWeek = 7;
      oneWeekFromNow.setDate(now.getDate() + daysInOneWeek);

      const signedUrl = await getSignedUrl(
        this.s3,
        new GetObjectCommand({
          Bucket: this.configService.getOrThrow('R2_BUCKET_NAME'),
          Key: flag.key,
        }),
        {
          expiresIn: 60 * 60 * 24 * 7, // 1 week
        },
      );
      await prisma.language.update({
        where: {
          id: flag.id,
        },
        data: {
          flagUrl: signedUrl,
          flagUrlExpireTimestamp: oneWeekFromNow,
        },
      });
    }
  }
}
