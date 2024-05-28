import { S3 } from '@aws-sdk/client-s3';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class S3Service extends S3 {
  constructor(protected readonly configService: ConfigService) {
    super({
      forcePathStyle: false,
      endpoint: `https://${configService.getOrThrow('CF_ACCOUNT_ID')}.r2.cloudflarestorage.com`,
      region: 'auto',
      credentials: {
        accessKeyId: configService.getOrThrow('R2_KEY_ID'),
        secretAccessKey: configService.getOrThrow('R2_KEY_SECRET'),
      },
    });
  }
}
