import { Test, TestingModule } from '@nestjs/testing';
import { RecallsController } from './recalls.controller';
import { RecallsService } from './recalls.service';

describe('RecallsController', () => {
  let controller: RecallsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [RecallsController],
      providers: [RecallsService],
    }).compile();

    controller = module.get<RecallsController>(RecallsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
