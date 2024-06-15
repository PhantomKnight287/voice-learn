import { Module } from '@nestjs/common';
import { VoicesService } from './voices.service';
import { VoicesController } from './voices.controller';

@Module({
  controllers: [VoicesController],
  providers: [VoicesService],
})
export class VoicesModule {}
