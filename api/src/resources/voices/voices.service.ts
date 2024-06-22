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
    voices.sort((a, b) => {
      const hasFreeA = a.tiers.includes('free') ? 0 : 1;
      const hasFreeB = b.tiers.includes('free') ? 0 : 1;
      return hasFreeA - hasFreeB;
    });
    return voices;
  }
}
