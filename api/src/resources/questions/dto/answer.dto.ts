import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsISO8601, IsString } from 'class-validator';

export class CreateAnswerDTO {
  @IsString()
  @ApiProperty()
  answer: string;

  @IsBoolean()
  @ApiProperty()
  last: boolean;

  @IsISO8601()
  @ApiProperty()
  startDate: string;

  @IsISO8601()
  @ApiProperty()
  endDate: string;
}
