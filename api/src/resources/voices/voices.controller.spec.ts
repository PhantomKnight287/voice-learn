import { Test, TestingModule } from '@nestjs/testing';
import { VoicesController } from './voices.controller';
import { VoicesService } from './voices.service';

describe('VoicesController', () => {
  let controller: VoicesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [VoicesController],
      providers: [VoicesService],
    }).compile();

    controller = module.get<VoicesController>(VoicesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
