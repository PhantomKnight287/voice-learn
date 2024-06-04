import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsString } from 'class-validator';

export class CreateAnswerDTO {
  @IsString()
  @ApiProperty()
  answer: string;

  @IsBoolean()
  @ApiProperty()
  last: boolean;
}
