import { Test, TestingModule } from '@nestjs/testing';
import { VoicesService } from './voices.service';

describe('VoicesService', () => {
  let service: VoicesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [VoicesService],
    }).compile();

    service = module.get<VoicesService>(VoicesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
