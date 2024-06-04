import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class LivesService {
  async removeHeart(userId: string) {
    const user = await prisma.user.findFirst({ where: { id: userId } });
    if (user.lives === 0)
      throw new HttpException('Lives are already 0.', HttpStatus.CONFLICT);
    await prisma.user.update({
      where: { id: userId },
      data: { lives: { decrement: 1 } },
    });
    return {
      lives: user.lives - 1,
    };
  }
}
