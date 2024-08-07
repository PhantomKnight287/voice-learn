import { IsString } from 'class-validator';

export class RemoveAvatarDTO {
  @IsString()
  updateReasonTitle: string;

  @IsString()
  updateReasonDescription: string;
}
