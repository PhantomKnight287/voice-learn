import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class CreateChatDTO {
  @IsString()
  @ApiProperty()
  name: string;

  @IsString()
  @ApiProperty()
  @IsOptional()
  initialPrompt?: string;

  @IsString()
  @ApiProperty()
  voiceId: string;

  @IsString()
  @ApiProperty()
  languageId: string;
}
