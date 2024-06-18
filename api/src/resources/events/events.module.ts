import { Module } from '@nestjs/common';
import { EventsService } from './events.service';
import { EventsController } from './events.controller';
import { GeminiService } from 'src/services/gemini/gemini.service';
import { S3Service } from 'src/services/s3/s3.service';

@Module({
  controllers: [EventsController],
  providers: [EventsService, GeminiService, S3Service],
})
export class EventsModule {}
