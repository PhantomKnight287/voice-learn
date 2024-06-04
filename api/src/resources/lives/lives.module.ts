import { Module } from '@nestjs/common';
import { LivesService } from './lives.service';
import { LivesController } from './lives.controller';

@Module({
  controllers: [LivesController],
  providers: [LivesService],
})
export class LivesModule {}
