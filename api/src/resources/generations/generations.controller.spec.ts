import { Test, TestingModule } from '@nestjs/testing';
import { GenerationsController } from './generations.controller';
import { GenerationsService } from './generations.service';

describe('GenerationsController', () => {
  let controller: GenerationsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [GenerationsController],
      providers: [GenerationsService],
    }).compile();

    controller = module.get<GenerationsController>(GenerationsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
