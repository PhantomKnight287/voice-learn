import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';
import { BuyCustomVoiceCredits } from './dto/buy-custom.dto';

const COST = 2;

@Injectable()
export class VoiceCreditsService {
  async buyOneVoiceCredit(userId: string) {
    const query = await prisma.$transaction(async (tx) => {
      const user = await tx.user.findFirst({ where: { id: userId } });
      if (user.emeralds < COST) {
        throw new HttpException('Not enough Emeralds.', HttpStatus.BAD_REQUEST);
      }
      return await tx.user.update({
        where: { id: userId },
        data: {
          voiceMessages: { increment: 1 },
          emeralds: { decrement: COST },
        },
      });
    });
    return {
      emeralds: query.emeralds,
      voiceMessages: query.voiceMessages,
    };
  }
  async buyTenVoiceCredits(userId: string) {
    const query = await prisma.$transaction(async (tx) => {
      const user = await tx.user.findFirst({ where: { id: userId } });
      if (user.emeralds < COST * 10) {
        throw new HttpException('Not enough Emeralds.', HttpStatus.BAD_REQUEST);
      }
      return await tx.user.update({
        where: { id: userId },
        data: {
          voiceMessages: { increment: 1 },
          emeralds: { decrement: COST * 10 },
        },
      });
    });
    return {
      emeralds: query.emeralds,
      voiceMessages: query.voiceMessages,
    };
  }
  async buyCustomVoiceCredits(
    userId: string,
    { count }: BuyCustomVoiceCredits,
  ) {
    const query = await prisma.$transaction(async (tx) => {
      const user = await tx.user.findFirst({ where: { id: userId } });

      if (!user) {
        throw new HttpException('User not found.', HttpStatus.NOT_FOUND);
      }

      const totalCost = COST * count;
      if (user.emeralds < totalCost) {
        throw new HttpException('Not enough Emeralds.', HttpStatus.BAD_REQUEST);
      }

      return await tx.user.update({
        where: { id: userId },
        data: {
          voiceMessages: { increment: count },
          emeralds: { decrement: totalCost },
        },
      });
    });

    return {
      emeralds: query.emeralds,
      voiceMessages: query.voiceMessages,
    };
  }
}
