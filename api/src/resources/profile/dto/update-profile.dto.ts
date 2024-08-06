import { IsEmail, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class UpdateProfileDTO {
  @IsString()
  @IsOptional()
  @IsNotEmpty({ message: 'Empty Name is not allowed' })
  name?: string;

  @IsOptional()
  @IsEmail(undefined, { message: 'Please enter a valid email.' })
  email?: string;

  @IsOptional()
  @IsString()
  avatar?: string;
}
