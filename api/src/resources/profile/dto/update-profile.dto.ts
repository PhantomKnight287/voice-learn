import { IsEmail, IsOptional, IsString } from 'class-validator';

export class UpdateProfileDTO {
  @IsString()
  @IsOptional()
  name?: string;

  @IsOptional()
  @IsEmail(undefined, { message: 'Please enter a valid email.' })
  email?: string;

  @IsOptional()
  @IsString()
  avatar?: string;
}
