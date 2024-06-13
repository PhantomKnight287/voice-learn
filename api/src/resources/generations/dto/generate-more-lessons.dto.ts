import { ApiProperty } from '@nestjs/swagger';
import { GenerationRequestType } from '@prisma/client';
import { IsEnum, IsOptional, IsString } from 'class-validator';

export class CreateMoreLessonsGenerationDTO {
  @IsString()
  @ApiProperty()
  @IsOptional()
  prompt?: string;

  @ApiProperty({
    enum: GenerationRequestType,
  })
  @IsEnum(GenerationRequestType)
  type: GenerationRequestType;

  @ApiProperty()
  @IsOptional()
  @IsString()
  id?: string;
}
