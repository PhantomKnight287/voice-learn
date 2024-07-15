import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsEmail, IsOptional, IsString } from 'class-validator';

export class SignInDTO {
  @ApiProperty()
  @IsEmail()
  email: string;

  @ApiProperty()
  @IsString()
  password: string;

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
