import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createId } from '@paralleldrive/cuid2';
import { randomUUID } from 'crypto';
import { prisma } from 'src/db';
import { S3Service } from 'src/services/s3/s3.service';
import { Response as R } from 'express';
import { verify } from 'jsonwebtoken';
import moment from 'moment';

@Injectable()
export class UploadsService {
  constructor(
    protected readonly s3: S3Service,
    protected readonly configService: ConfigService,
  ) {}
  async uploadToPrivate(userId: string, file: Express.Multer.File) {
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
        signingRegion: 'weur',
      },
    );
    const upload = await prisma.upload.create({
      data: {
        id: `upload_${createId()}`,
        key: fileKey,
        url: signedUrl,
        expiresAt: new Date(moment.utc().unix() + 24 * 60 * 60 * 1000),
        userId,
      },
    });
    return {
      id: upload.id,
      url: upload.url,
    };
  }

  async redirectToPublicUrl(token: string, chatId: string, id: string, res: R) {
    if (!token || !chatId)
      throw new HttpException(
        'ChatId and Token must be passed in query',
        HttpStatus.BAD_REQUEST,
      );
    const decoded = verify(
      token,
      this.configService.getOrThrow('JWT_SECRET'),
    ) as { id: string };
    const chat = await prisma.chat.findFirst({
      where: {
        userId: decoded.id,
        id: chatId,
      },
    });
    if (!chat) throw new HttpException('No chat found.', HttpStatus.NOT_FOUND);
    const upload = await prisma.upload.findFirst({
      where: {
        id: id,
      },
    });
    if (!upload)
      throw new HttpException('No upload found.', HttpStatus.NOT_FOUND);

    const now = moment().utc().toDate();
    const oneWeekFromNow = new Date(now);

    oneWeekFromNow.setDate(now.getDate() + 7);

    const signedUrl = await getSignedUrl(
      this.s3,
      new GetObjectCommand({
        Bucket: this.configService.getOrThrow('R2_BUCKET_NAME'),
        Key: upload.key,
      }),
      {
        expiresIn: 60 * 60 * 24 * 7, // 1 week
      },
    );
    await prisma.upload.update({
      where: {
        id: upload.id,
      },
      data: {
        url: signedUrl,
        expiresAt: oneWeekFromNow,
      },
    });
    res.redirect(upload.url);
  }

  async uploadToPublicBucket(userId: string, file: Express.Multer.File) {
    const fileKey = `${randomUUID()}____${userId}___${file.originalname}`;
    const payload = await this.s3.putObject({
      Bucket: this.configService.getOrThrow('R2_PUBLIC_BUCKET_NAME'),
      Key: fileKey,
      Body: file.buffer,
      ContentType: file.mimetype,
    });

    const upload = await prisma.upload.create({
      data: {
        id: `upload_${createId()}`,
        key: fileKey,
        url: `${process.env.R2_PUBLIC_BUCKET_URL}/${fileKey}`,
        expiresAt: new Date(moment.utc().unix() + 24 * 60 * 60 * 1000),
        userId,
      },
    });
    return {
      id: upload.id,
      url: upload.url,
    };
  }
}
