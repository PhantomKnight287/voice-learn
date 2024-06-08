import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class ProfileService {
  async getMyProfile(userId: string) {
    const user = await prisma.user.findFirst({
      where: {
        id: userId,
      },
      omit: {
        password: true,
        email: true,
      },
      include: {
        paths: {
          select: {
            language: {
              select: {
                flagUrl: true,
              },
            },
          },
        },
      },
    });
    return user;
  }
}
