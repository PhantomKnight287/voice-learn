import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
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
  async getUserProfile(userId: string) {
    const user = await prisma.user.findFirst({
      where: {
        id: userId,
      },
      omit: {
        password: true,
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
    if (!user) throw new HttpException('No user found.', HttpStatus.NOT_FOUND);
    return user;
  }
}
