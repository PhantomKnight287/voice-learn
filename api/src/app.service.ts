import { Injectable } from '@nestjs/common';
import { S3Service } from './services/s3/s3.service';
import { readFileSync } from 'fs';
import { prisma } from './db';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { createId } from '@paralleldrive/cuid2';
@Injectable()
export class AppService {
  constructor(
    protected readonly s3: S3Service,
    protected readonly configService: ConfigService,
  ) {
    this.saveFlags();
  }
  getHello(): string {
    return 'Hello World!';
  }

  async saveFlags() {
    const file = readFileSync(
      `${process.cwd()}/public/flags/images.json`,
      'utf-8',
    );
    const flags = JSON.parse(file) as { name: string; path: string }[];
    for (const flag of flags) {
      const savedFlag = await prisma.language.findFirst({
        where: {
          name: flag.name,
        },
      });
      if (savedFlag) continue;
      const imageFile = readFileSync(flag.path);
      const fileKey = `${flag.name}-${randomUUID()}`;
      const payload = await this.s3.putObject({
        Bucket: this.configService.getOrThrow('R2_BUCKET_NAME'),
        Key: fileKey,
        Body: imageFile,
        ContentType: flag.path.endsWith('.png') ? 'image/png' : 'image/webp',
      });
      const now = new Date();
      const oneWeekFromNow = new Date(now);

      const daysInOneWeek = 7;
      oneWeekFromNow.setDate(now.getDate() + daysInOneWeek);

      const signedUrl = await getSignedUrl(
        this.s3,
        new GetObjectCommand({
          Bucket: this.configService.getOrThrow('R2_BUCKET_NAME'),
          Key: fileKey,
        }),
        {
          expiresIn: 60 * 60 * 24 * 7, // 1 week
        },
      );
      await prisma.language.create({
        data: {
          flagUrl: signedUrl,
          flagUrlExpireTimestamp: oneWeekFromNow,
          id: `language_${createId()}`,
          name: flag.name,
        },
      });
    }
  }
}
