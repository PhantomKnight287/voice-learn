import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class CreateMoreLessonsGenerationDTO {
  @IsString()
  @ApiProperty()
  @IsOptional()
  prompt?: string;
}
