import { IsNumber, IsPositive } from 'class-validator';

export class BuyCustomVoiceCredits {
  @IsNumber()
  @IsPositive()
  count: number;
}
