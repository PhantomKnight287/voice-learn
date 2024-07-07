import { Module } from '@nestjs/common';
import { RecallsService } from './recalls.service';
import { RecallsController } from './recalls.controller';

@Module({
  controllers: [RecallsController],
  providers: [RecallsService],
})
export class RecallsModule {}
