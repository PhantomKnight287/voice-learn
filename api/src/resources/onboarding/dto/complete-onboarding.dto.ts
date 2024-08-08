import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class CompleteOnBoardingDTO {
  @IsString()
  @ApiProperty()
  reason: string;

  @IsString()
  @ApiProperty()
  languageId: string;

  @IsString()
  @ApiProperty()
  knowledge: string;

  @IsString()
  @ApiProperty()
  @IsOptional()
  analytics?: string;
}
