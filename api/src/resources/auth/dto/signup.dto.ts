import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsEmail, IsOptional, IsString } from 'class-validator';

export class SignupDTO {
  @ApiProperty()
  @IsEmail()
  email: string;

  @IsString()
  @ApiProperty()
  password: string;

  @IsString()
  @ApiProperty()
  name: string;

  @ApiProperty()
  @IsOptional()
  @IsString()
  timezone: string;

  @ApiProperty()
  @IsOptional()
  @IsString()
  timeZoneOffset: string;

  @IsBoolean()
  @IsOptional()
  parsed?: boolean;
}
