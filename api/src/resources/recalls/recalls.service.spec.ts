import { Test, TestingModule } from '@nestjs/testing';
import { RecallsService } from './recalls.service';

describe('RecallsService', () => {
  let service: RecallsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [RecallsService],
    }).compile();

    service = module.get<RecallsService>(RecallsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
