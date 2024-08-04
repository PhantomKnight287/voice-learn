import { Test, TestingModule } from '@nestjs/testing';
import { VoiceCreditsController } from './voice-credits.controller';
import { VoiceCreditsService } from './voice-credits.service';

describe('VoiceCreditsController', () => {
  let controller: VoiceCreditsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [VoiceCreditsController],
      providers: [VoiceCreditsService],
    }).compile();

    controller = module.get<VoiceCreditsController>(VoiceCreditsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
