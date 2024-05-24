import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class SignupDTO {
  @ApiProperty()
  @IsString()
  email: string;

  @IsString()
  @ApiProperty()
  password: string;

  @IsString()
  @ApiProperty()
  name: string;
}
