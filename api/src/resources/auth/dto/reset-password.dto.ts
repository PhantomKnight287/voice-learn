import { IsEmail } from 'class-validator';

export class ResetPasswordDTO {
  @IsEmail(undefined, { message: 'Please enter a valid email' })
  email: string;
}
