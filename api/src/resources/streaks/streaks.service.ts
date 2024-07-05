import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class StreaksService {
  async getUserStreaks(userId: string, month: number, year: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999);
    const streaks = await prisma.streak.findMany({
      where: {
        userId,
        createdAt: {
          gte: startDate,
          lte: endDate,
        },
      },
      select: {
        createdAt: true,
        id: true,
        type:true,
      },
      orderBy: [
        {
          createdAt: 'asc',
        },
      ],
    });
    return streaks;
  }
}
