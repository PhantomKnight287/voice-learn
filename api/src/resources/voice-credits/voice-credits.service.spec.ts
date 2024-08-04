import { Test, TestingModule } from '@nestjs/testing';
import { VoiceCreditsService } from './voice-credits.service';

describe('VoiceCreditsService', () => {
  let service: VoiceCreditsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [VoiceCreditsService],
    }).compile();

    service = module.get<VoiceCreditsService>(VoiceCreditsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
