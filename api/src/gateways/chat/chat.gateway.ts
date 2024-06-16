import {
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { ChatService } from './chat.service';
import { verify } from 'jsonwebtoken';
import { prisma } from 'src/db';
import { Socket } from 'socket.io';
import { z } from 'zod';
import { messageSchema } from './schema/message';
import { createId } from '@paralleldrive/cuid2';
import { GeminiService } from 'src/services/gemini/gemini.service';
import { llmTextResponse } from './schema/response';

function isJSONString(str) {
  try {
    const parsed = JSON.parse(str);
    // Check if the parsed result is an object or array (valid JSON types)
    return parsed && (typeof parsed === 'object' || Array.isArray(parsed));
  } catch (e) {
    return false;
  }
}

@WebSocketGateway({
  transports: ['websocket'],
})
export class ChatGateway implements OnGatewayConnection {
  constructor(
    private readonly chatService: ChatService,
    private readonly gemini: GeminiService,
  ) {}
  async handleConnection(client: Socket) {
    console.log('connection');
    const rawToken = client.handshake.auth.token;
    if (!rawToken) {
      client.emit('error', 'No token specified');
      return client.disconnect(true);
    }
    const token = rawToken.replace('Bearer ', '');
    if (!token) {
      client.emit('error', 'No token specified');
      return client.disconnect(true);
    }
    if (!client.handshake.query.chatId) {
      client.emit('error', 'Chat ID is required');
      return client.disconnect(true);
    }
    try {
      const { id } = verify(token, process.env.JWT_SECRET) as any;
      const chat = await prisma.chat.findFirst({
        where: {
          id: client.handshake.query.chatId as string,
          userId: id,
        },
      });
      if (!chat) {
        client.emit('error', 'No chat found');
        client.disconnect(true);
      }
    } catch (e) {
      return client.emit('error', 'Invalid Token Provided');
    }
    client.join(client.handshake.query.chatId);
  }

  @SubscribeMessage('message')
  async handleMessage(client: Socket, payload: z.infer<typeof messageSchema>) {
    const result = messageSchema.safeParse(payload);
    if (result.success === false) {
      return client.emit('error', result.error.errors[0].message);
    }
    const message = await prisma.message.create({
      data: {
        id: `message_${createId()}`,
        content: payload.message.split(' ').map((word) => ({ word })),
        author: 'User',
        chatId: client.handshake.query.chatId as string,
      },
    });
    client.nsp
      .in(client.handshake.query.chatId)
      .emit('message', { ...message, refId: payload.refId });
    const chat = await prisma.chat.findFirst({
      where: {
        id: client.handshake.query.chatId as string,
      },
      include: {
        language: true,
        messages: true,
      },
    });
    try {
      const res = await this.gemini.generateObject({
        schema: llmTextResponse,
        messages: [
          {
            role: 'system',
            content: `${chat.initialPrompt}. ${
              chat.language.name.toLocaleLowerCase() === 'multiple'
                ? 'Reply in language the question is asked'
                : `Reply in ${chat.language.name}`
            }. The actions or expressions are inside asterisks. Try to add some expressions into your message as well. You are only allowed to do textual conversations and not provide any code help. You are free to tell others that you are made by OpenAI. `,
          },
          {
            role: 'system',
            content: `Your response must be an array of objects where 'word' will be the actual word in ${chat.language.name} and 'translation' will be translation in english. Example: [{"word":"Guten","translation":"Good",},{"word":"morgen","translation":"morning"}]
          
          Do not generate escape characters
          `,
          },
          //@ts-expect-error
          ...chat.messages.map((message) => ({
            role: message.author === 'Bot' ? 'assistant' : 'user',
            content: message.content
              .map((message) => (message as { word: string }).word)
              .join(' '),
          })),
          {
            content: payload.message,
            //@ts-expect-error
            role: 'user',
          },
        ],
      });

      const llmMessage = await prisma.message.create({
        data: {
          id: `message_${createId()}`,
          content: res.object as z.infer<typeof llmTextResponse>,
          author: 'Bot',
          chatId: client.handshake.query.chatId as string,
        },
      });
      client.nsp
        .in(client.handshake.query.chatId)
        .emit('response_end', llmMessage);
    } catch (error) {
      console.log(error);
      client.nsp
        .in(client.handshake.query.chatId)
        .emit('response_end', message);
    }
  }
}
