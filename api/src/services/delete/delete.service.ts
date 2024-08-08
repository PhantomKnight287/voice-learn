import { Injectable, Logger } from '@nestjs/common';
import { prisma } from 'src/db';
import { S3Service } from '../s3/s3.service';
import { ConfigService } from '@nestjs/config';
import { deleteAccountMail } from '../../emails/auth/delete';
import { OnEvent } from '@nestjs/event-emitter';

@Injectable()
export class DeleteService {
  logger = new Logger(DeleteService.name);
  constructor(
    protected readonly s3Service: S3Service,
    protected readonly configService: ConfigService,
  ) {}

  @OnEvent('user.delete')
  async deleteUser(userId: string) {
    const uploads = await prisma.upload.findMany({
      where: {
        userId,
      },
    });

    const publicUploads = uploads.filter((u) =>
      u.url.startsWith(this.configService.getOrThrow('R2_PUBLIC_BUCKET_URL')),
    );
    const privateUploads = uploads.filter(
      (u) =>
        !u.url.startsWith(
          this.configService.getOrThrow('R2_PUBLIC_BUCKET_URL'),
        ),
    );
    if (publicUploads.length) {
      try {
        const data = await this.s3Service.deleteObjects({
          Bucket: this.configService.getOrThrow('R2_PUBLIC_BUCKET_NAME'),
          Delete: {
            Objects: publicUploads.map((e) => ({ Key: e.key })),
          },
        });
        console.log(data);
      } catch (e) {
        this.logger.error('Failed to delete public uploads: ');
        this.logger.log(e);
      }
    }
    if (privateUploads.length) {
      try {
        const data = await this.s3Service.deleteObjects({
          Bucket: this.configService.getOrThrow('R2_BUCKET_NAME'),
          Delete: {
            Objects: publicUploads.map((e) => ({ Key: e.key })),
          },
        });
        console.log(data);
      } catch (e) {
        this.logger.error('Failed to delete private uploads: ');
        this.logger.log(e);
      }
    }

    const user = await prisma.user.findFirst({ where: { id: userId } });
    const req = await fetch(`https://emailthing.xyz/api/v0/send`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.EMAILTHING_TOKEN}`,
        'Content-type': 'application/json',
      },
      body: JSON.stringify({
        from: 'VoiceLearn Support <support@voicelearn.tech>',
        to: [user.email],
        subject: 'Your account has not been deleted',
        html: deleteAccountMail(user.name),
      }),
    });
    const res = await req.json();
    if (!res.success) {
      this.logger.error('Failed to send email to user');
    }
    await prisma.user.delete({
      where: {
        id: userId,
      },
    });
  }
}
