import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class LivesService {
  async buyOneLife(userId: string) {
    const query = await prisma.$transaction(async (tx) => {
      const user = await tx.user.findFirst({ where: { id: userId } });
      if (user.emeralds < 4) {
        throw new HttpException('Not enough Emeralds.', HttpStatus.BAD_REQUEST);
      }
      return await tx.user.update({
        where: { id: userId },
        data: {
          lives: { increment: 1 },
          emeralds: { decrement: 4 },
        },
      });
    });
    return {
      emeralds: query.emeralds,
      lives: query.lives,
    };
  }
  async refillAllLives(userId: string) {
    const query = await prisma.$transaction(async (tx) => {
      const user = await tx.user.findFirst({ where: { id: userId } });

      if (!user) {
        throw new HttpException('User not found.', HttpStatus.NOT_FOUND);
      }

      const livesToAdd = 5 - user.lives;
      const requiredEmeralds = livesToAdd * 4;

      if (user.emeralds < requiredEmeralds) {
        throw new HttpException('Not enough Emeralds.', HttpStatus.BAD_REQUEST);
      }

      return await tx.user.update({
        where: { id: userId },
        data: {
          lives: { set: 5 },
          emeralds: { decrement: requiredEmeralds },
        },
      });
    });

    return {
      emeralds: query.emeralds,
      lives: query.lives,
    };
  }
}
