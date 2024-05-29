import { Module } from '@nestjs/common';
import { EventsService } from './events.service';
import { EventsController } from './events.controller';
import { GeminiService } from 'src/services/gemini/gemini.service';

@Module({
  controllers: [EventsController],
  providers: [EventsService, GeminiService],
})
export class EventsModule {}
