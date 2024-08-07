import { IsNumber, IsOptional, IsString } from 'class-validator';

export class UpdateUserDTO {
  @IsString()
  @IsOptional()
  name: string;

  @IsNumber()
  @IsOptional()
  xp: number;

  @IsNumber()
  @IsOptional()
  lives: number;

  @IsNumber()
  @IsOptional()
  voiceMessages: number;

  @IsNumber()
  @IsOptional()
  emeralds: number;

  @IsString()
  updateReasonTitle: string;

  @IsString()
  updateReasonDescription: string;
}
