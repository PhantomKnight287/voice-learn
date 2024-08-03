import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class VoicesService {
  async listAllVoices() {
    const voices = await prisma.voice.findMany({
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

    return voices;
  }
}
