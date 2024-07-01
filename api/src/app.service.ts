import { Injectable } from '@nestjs/common';
import { S3Service } from './services/s3/s3.service';
import { readFileSync, writeFileSync } from 'fs';
import { prisma } from './db';
import { ConfigService } from '@nestjs/config';
import { createHash, randomUUID } from 'crypto';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { createId } from '@paralleldrive/cuid2';
import { queue } from './services/queue/queue.service';
import moment from 'moment';

@Injectable()
export class AppService {
  constructor(
    protected readonly s3: S3Service,
    protected readonly configService: ConfigService,
  ) {
    this.saveFlags();
    this.generateAvatarHash();
  }
  async getHello() {
    for (let i = 0; i < 20; i++) {
      await queue.addToQueue({
        id: String(i),
        type: 'learning_path',
      });
      if (i == 10)
        await queue.addToQueueWithPriority({
          id: 'priority',
          type: 'learning_path',
        });
    }
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
      const imageFile = readFileSync(
        `${process.cwd()}/public/flags/rounded/${flag.path.replace('.webp', '.png')}`,
      );
      const fileKey = `${flag.name}-${randomUUID()}`;
      const payload = await this.s3.putObject({
        Bucket: this.configService.getOrThrow('R2_PUBLIC_BUCKET_NAME'),
        Key: fileKey,
        Body: imageFile,
        ContentType: 'image/png',
      });

      await prisma.language.create({
        data: {
          flagUrl: `${process.env.R2_PUBLIC_BUCKET_URL}/${fileKey}`,
          id: `language_${createId()}`,
          name: flag.name,
          key: fileKey,
        },
      });
    }
  }

  async generateAvatarHash() {
    const users = await prisma.user.findMany({ where: { avatarHash: null } });
    for (const user of users) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          avatarHash: createHash('sha256')
            .update(user.email.trim().toLowerCase())
            .digest('hex'),
        },
      });
    }
  }
}
