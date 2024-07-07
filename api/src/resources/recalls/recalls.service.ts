import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class RecallsService {
  async getStacks(userId: string, page: number) {
    const stacks = await prisma.stack.paginate({
      page,
      limit: 20,
      where: {
        userId,
      },
      include: {
        _count: {
          select: {
            notes: true,
          },
        },
      },
    });
    return stacks;
  }
}
