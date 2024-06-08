import { Test, TestingModule } from '@nestjs/testing';
import { GenerationsService } from './generations.service';

describe('GenerationsService', () => {
  let service: GenerationsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [GenerationsService],
    }).compile();

    service = module.get<GenerationsService>(GenerationsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
