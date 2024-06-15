import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class VoicesService {
  async listAllVoices() {
    return await prisma.voice.findMany({
      include: {
        _count: {
          select: {
            chats: true,
          },
        },
      },
      orderBy: [
        {
          name: 'asc',
        },
      ],
    });
  }
}
