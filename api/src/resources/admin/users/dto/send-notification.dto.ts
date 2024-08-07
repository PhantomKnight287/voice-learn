import { NotificationType } from '@prisma/client';
import { IsEnum, IsString } from 'class-validator';

export class SendNotificationDTO {
  @IsString()
  title: string;

  @IsString()
  description: string;

  @IsEnum(NotificationType)
  type: NotificationType;
}
