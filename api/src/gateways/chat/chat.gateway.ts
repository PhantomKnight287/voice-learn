import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
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
import { Subscription } from 'rxjs';
import { queue } from 'src/services/queue/queue.service';
import {
  messageSubject,
  openai,
  queuePositionSubject,
  userUpdateSubject,
} from 'src/constants';
import { join } from 'path';
import { createReadStream, createWriteStream } from 'fs';
import { promisify } from 'util';
import { pipeline } from 'stream';

const streamPipeline = promisify(pipeline);

@WebSocketGateway({
  transports: ['websocket'],
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  subscriptions: Record<string, Subscription> = {};
  queueSubscriptions: Record<string, Subscription> = {};
  userUpdateSubscription: Record<string, Subscription> = {};
  constructor(
    private readonly chatService: ChatService,
    private readonly gemini: GeminiService,
  ) {}
  async handleConnection(client: Socket) {
    const chatId = client.handshake.query.chatId;

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
    if (!chatId) {
      client.emit('error', 'Chat ID is required');
      return client.disconnect(true);
    }
    try {
      const { id } = verify(token, process.env.JWT_SECRET) as any;
      const chat = await prisma.chat.findFirst({
        where: {
          id: chatId as string,
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
    client.join(chatId);
    this.subscriptions[chatId as string] = messageSubject.subscribe((data) => {
      client?.nsp?.in(data.chatId).emit('response_end', data);
    });
    this.queueSubscriptions[chatId as string] = queuePositionSubject.subscribe(
      (data) => {
        client?.nsp?.in(chatId).emit('queue', data);
      },
    );
    this.userUpdateSubscription[chatId as string] = userUpdateSubject.subscribe(
      (data) => {
        client?.nsp?.in(chatId).emit('user_update', data);
      },
    );
  }

  handleDisconnect(client: Socket) {
    this.subscriptions[client.handshake.query.chatId as string]?.unsubscribe();
    this.chatService[client.handshake.query.chatId as string]?.unsubscribe();
    this.queueSubscriptions[
      client.handshake.query.chatId as string
    ]?.unsubscribe();
  }

  @SubscribeMessage('message')
  async handleMessage(client: Socket, payload: z.infer<typeof messageSchema>) {
    const result = messageSchema.safeParse(payload);
    if (result.success === false) {
      return client.emit('error', result.error.errors[0].message);
    }
    let addToQueue = true;
    let response = payload.message;
    if (payload.attachmentId) {
      const attachment = await prisma.upload.findFirst({
        where: { id: payload.attachmentId },
      });
      if (!attachment) return client.emit('error', 'Invalid attachment');
      const rawToken = client.handshake.auth.token;
      const token = rawToken.replace('Bearer ', '');
      const user = await prisma.user.findFirst({
        where: {
          id: (verify(token, process.env.JWT_SECRET) as any).id,
        },
      });
      if (user.emeralds <= 0) {
        client.emit(
          'error',
          'Not enough emeralds to continue in voice chat mode. Please use text only chat.',
        );
        addToQueue = false;
      }
      const res = await fetch(attachment.url);
      if (!res.ok)
        throw new Error(`Failed to fetch ${attachment.url}: ${res.statusText}`);
      const filePath = join(
        process.cwd(),
        'public',
        'downloads',
        attachment.key,
      );
      const fileStream = createWriteStream(filePath);
      //@ts-expect-error
      await streamPipeline(res.body, fileStream);
      const whipserRes = await openai.audio.transcriptions.create({
        model: 'whisper-1',
        response_format: 'json',
        file: createReadStream(filePath),
      });
      if (whipserRes.text) {
        const arr = whipserRes.text;
        response = arr;
      }
    }
    const message = await prisma.message.create({
      data: {
        id: `message_${createId()}`,
        content: response.split(' ').map((e) => ({ word: e })),
        author: 'User',
        chatId: client.handshake.query.chatId as string,
        attachmentId: payload.attachmentId,
        audioDuration: payload.audioDuration,
      },
      include: {
        attachment: { select: { id: true } },
      },
    });
    client.nsp
      .in(client.handshake.query.chatId)
      .emit('message', { ...message, refId: payload.refId });
    if (addToQueue) {
      const position = await queue.addToQueue({
        id: message.chatId,
        type: 'chat',
        messageId: message.id,
      });

      client.nsp
        .in(message.chatId)
        .emit('queue', position !== null ? position : -1);
    }
  }

  @SubscribeMessage('queue_status')
  async handleQueueStatus(client: Socket, payload: { messageId: string }) {
    if (!payload.messageId)
      return client.emit('error', 'Please provide message id.');
    const position = await queue.getPositionInQueue({
      id: client.handshake.query.chatId as string,
      type: 'chat',
      messageId: payload.messageId,
    });

    client.nsp
      .in(client.handshake.query.chatId)
      .emit('queue', position !== null ? position + 1 : -1);
  }
}
