import { IsJWT, IsString } from 'class-validator';

export class ResetPasswordSubmitDTO {
  @IsString()
  password: string;

  @IsJWT({ message: 'Invalid Token' })
  token: string;
}
