import { Body, Controller, Post } from '@nestjs/common';
import { VoiceCreditsService } from './voice-credits.service';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';
import { BuyCustomVoiceCredits } from './dto/buy-custom.dto';

@Controller('voice-credits')
export class VoiceCreditsController {
  constructor(private readonly voiceCreditsService: VoiceCreditsService) {}

  @Post('buy')
  buyCustomVoiceCredits(
    @Auth() auth: User,
    @Body() body: BuyCustomVoiceCredits,
  ) {
    return this.voiceCreditsService.buyCustomVoiceCredits(auth.id, body);
  }
}
