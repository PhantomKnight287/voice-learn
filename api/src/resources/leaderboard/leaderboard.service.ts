import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class LeaderboardService {
  async getLeaderBoard(page: number) {
    const users = await prisma.user.paginate({
      select: {
        xp: true,
        name: true,
        id: true,
        avatarHash: true,
        avatar: true,
      },
      where: {
        xp: {
          gt: 0,
        },
      },
      orderBy: [
        {
          xp: 'desc',
        },
      ],
      limit: 30,
      page: page,
    });
    return users.result;
  }
}
