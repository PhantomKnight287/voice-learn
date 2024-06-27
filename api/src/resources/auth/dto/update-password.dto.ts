import { IsString } from 'class-validator';
import { MatchPasswords } from 'src/decorators/match-password/match-password.decorator';

export class UpdatePasswordDTO {
  @IsString()
  currentPassword: string;

  @IsString()
  newPassword: string;

  @IsString()
  @MatchPasswords({ message: 'New password and confirm password do not match' })
  confirmPassword: string;
}
