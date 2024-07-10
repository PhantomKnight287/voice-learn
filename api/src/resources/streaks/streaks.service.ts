import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
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
        type: true,
      },
      orderBy: [
        {
          createdAt: 'asc',
        },
      ],
    });
    return streaks;
  }

  async getStreakShields(userId: string) {
    const user = await prisma.user.findFirst({ where: { id: userId } });
    return {
      shields: user.streakShields,
    };
  }

  async buyOneShield(userId: string) {
    const user = await prisma.user.findFirst({ where: { id: userId } });
    const shields = user.streakShields;
    if (shields >= 5)
      throw new HttpException(
        'You cannot buy more streak shields',

        HttpStatus.CONFLICT,
      );

    if (user.emeralds < 10) {
      throw new HttpException(
        'You do not have enough emeralds to refill streak shields',
        HttpStatus.PAYMENT_REQUIRED,
      );
    }
    await prisma.user.update({
      where: { id: user.id },
      data: {
        streakShields: { increment: 1 },
        emeralds: {
          decrement: 10,
        },
      },
    });
    return {
      id: userId,
      emeralds: user.emeralds - 10,
      shields: user.streakShields + 1,
    };
  }
  async refillShields(userId: string) {
    const user = await prisma.user.findFirst({ where: { id: userId } });
    const shields = user.streakShields;

    if (shields >= 5) {
      throw new HttpException(
        'You cannot buy more streak shields',
        HttpStatus.CONFLICT,
      );
    }

    const shieldsToAdd = 5 - shields;
    const totalCost = shieldsToAdd * 10;

    if (user.emeralds < totalCost) {
      throw new HttpException(
        'You do not have enough emeralds to refill streak shields',
        HttpStatus.PAYMENT_REQUIRED,
      );
    }

    await prisma.user.update({
      where: { id: user.id },
      data: {
        streakShields: shields + shieldsToAdd,
        emeralds: {
          decrement: totalCost,
        },
      },
    });

    return {
      id: userId,
      shields: 5,
      emeralds: user.emeralds - totalCost,
    };
  }
}
