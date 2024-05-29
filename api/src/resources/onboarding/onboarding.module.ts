import { Module } from '@nestjs/common';
import { OnboardingService } from './onboarding.service';
import { OnboardingController } from './onboarding.controller';

@Module({
  imports: [],
  controllers: [OnboardingController],
  providers: [OnboardingService],
  exports: [],
})
export class OnboardingModule {}
