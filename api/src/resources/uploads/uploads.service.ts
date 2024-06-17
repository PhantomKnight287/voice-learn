import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createId } from '@paralleldrive/cuid2';
import { randomUUID } from 'crypto';
import { prisma } from 'src/db';
import { S3Service } from 'src/services/s3/s3.service';

@Injectable()
export class UploadsService {
  constructor(
    protected readonly s3: S3Service,
    protected readonly configService: ConfigService,
  ) {}
  async uploadImage(userId: string, file: Express.Multer.File) {
    const fileKey = `${randomUUID()}____${userId}___${file.originalname}`;
    const payload = await this.s3.putObject({
      Bucket: this.configService.getOrThrow('R2_BUCKET_NAME'),
      Key: fileKey,
      Body: file.buffer,
      ContentType: file.mimetype,
    });
    const signedUrl = await getSignedUrl(
      this.s3,
      new GetObjectCommand({
        Bucket: this.configService.getOrThrow('R2_BUCKET_NAME'),
        Key: fileKey,
      }),
      {
        expiresIn: 60 * 60 * 24, // 1 day
      },
    );
    const upload = await prisma.upload.create({
      data: {
        id: `upload_${createId()}`,
        key: fileKey,
        url: signedUrl,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      },
    });
    return {
      id: upload.id,
    };
  }
}
