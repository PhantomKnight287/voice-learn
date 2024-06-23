import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';
import { CreateChatDTO } from './dto/create-chat.dto';
import { createId } from '@paralleldrive/cuid2';
import { locales } from 'src/constants';

@Injectable()
export class ChatsService {
  async getMyChats(userId: string, page?: string) {
    if (page && isNaN(page as unknown as any))
      throw new HttpException(
        "NaN specified as 'page'",
        HttpStatus.BAD_REQUEST,
      );
    const chats = await prisma.chat.paginate({
      where: {
        userId,
      },
      limit: 20,
      page: isNaN(page as unknown as any) ? 1 : parseInt(page),
      include: {
        messages: {
          take: 1,
          orderBy: [
            {
              createdAt: 'desc',
            },
          ],
          select: {
            content: true,
          },
        },
        language: {
          select: {
            flagUrl: true,
            name: true,
          },
        },
        voice: {
          select: {
            name: true,
          },
        },
      },
      orderBy: [
        {
          createdAt: 'desc',
        },
      ],
    });

    return chats.result;
  }

  async createChat(body: CreateChatDTO, userId: string) {
    const language = await prisma.language.findFirst({
      where: { id: body.languageId },
    });
    if (!language)
      throw new HttpException(
        'Invalid Language Selection.',
        HttpStatus.NOT_FOUND,
      );
    const voice = await prisma.voice.findFirst({ where: { id: body.voiceId } });
    if (!voice)
      throw new HttpException('Invalid Voice Selection.', HttpStatus.NOT_FOUND);
    const chat = await prisma.chat.create({
      data: {
        id: `chat_${createId()}`,
        name: body.name,
        initialPrompt: body.initialPrompt,
        languageId: body.languageId,
        voiceId: body.voiceId,
        userId,
      },
    });
    return {
      id: chat.id,
    };
  }

  async getChatInfo(userId: string, chatId: string) {
    const chat = await prisma.chat.findFirst({
      where: {
        userId,
        id: chatId,
      },
      include: {
        messages: {
          take: 20,
          orderBy: [
            {
              createdAt: 'desc',
            },
          ],
          include: {
            attachment: {
              select: {
                id: true,
              },
            },
          },
        },
        language: {
          select: {
            flagUrl: true,
            name: true,
          },
        },
        voice: {
          select: {
            name: true,
          },
        },
      },
    });
    if (!chat) throw new HttpException('No Chat Found.', HttpStatus.NOT_FOUND);
    return { ...chat, locale: locales[chat.language.name] };
  }

  async getLatestMessages(userId: string, chatId: string) {
    const chat = await prisma.chat.findFirst({
      where: {
        userId,
        id: chatId,
      },
    });
    if (!chat) throw new HttpException('No Chat Found.', HttpStatus.NOT_FOUND);
    const messages = await prisma.message.findMany({
      where: {
        chat: {
          userId,
          id: chatId,
        },
      },
      take: 20,
      include: {
        attachment: { select: { id: true } },
      },
    });
    return messages;
  }

  async fetchOlderMessages(
    userId: string,
    chatId: string,
    lastMessageId: string,
  ) {
    if (!lastMessageId)
      throw new HttpException(
        'Please provide last message id',
        HttpStatus.BAD_REQUEST,
      );
    const chat = await prisma.chat.findFirst({
      where: {
        userId,
        id: chatId,
      },
    });
    if (!chat) throw new HttpException('No Chat Found.', HttpStatus.NOT_FOUND);
    const messages = await prisma.message.findMany({
      where: {
        chat: {
          userId,
          id: chatId,
        },
      },
      take: -20,
      skip: 1,
      cursor: {
        id: lastMessageId,
      },
      orderBy: {
        createdAt: 'asc',
      },
      include: {
        attachment: { select: { id: true } },
      },
    });
    return messages;
  }
}
