import { Module } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { GeminiService } from 'src/services/gemini/gemini.service';
import { S3Service } from 'src/services/s3/s3.service';

@Module({
  providers: [ChatGateway, ChatService, GeminiService,S3Service,],
  imports: [],
})
export class ChatModule {}
