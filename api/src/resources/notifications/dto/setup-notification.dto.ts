import { IsString } from 'class-validator';

export class SetupNotificationsDTO {
  @IsString()
  id: string;
}
