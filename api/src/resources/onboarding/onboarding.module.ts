import { Module } from '@nestjs/common';
import { OnboardingService } from './onboarding.service';
import { OnboardingController } from './onboarding.controller';
import { QueueService } from 'src/services/queue/queue.service';

@Module({
  imports: [],
  controllers: [OnboardingController],
  providers: [OnboardingService, QueueService],
  exports: [],
})
export class OnboardingModule {}
