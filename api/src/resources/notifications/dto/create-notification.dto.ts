import { NotificationType } from '@prisma/client';
import { IsEnum, IsString } from 'class-validator';

export class CreateNotificationDTO {
  @IsString()
  title: string;

  @IsString()
  description: string;

  @IsEnum(NotificationType)
  type: NotificationType;
}
