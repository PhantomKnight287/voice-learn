import { Module } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { GeminiService } from 'src/services/gemini/gemini.service';

@Module({
  providers: [ChatGateway, ChatService,GeminiService],
  imports: [],
})
export class ChatModule {}
