import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';
import { UpdateProfileDTO } from './dto/update-profile.dto';
import { createHash } from 'crypto';

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
    if (!user) throw new HttpException('No user found.', HttpStatus.NOT_FOUND);
    return user;
  }

  async updateProfile(body: UpdateProfileDTO, userId: string) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        email: body.email,
        name: body.name,
        avatarHash: body.email
          ? createHash('sha256')
              .update(body.email.trim().toLowerCase())
              .digest('hex')
          : undefined,
      },
    });
    return {
      name: user.name,
      email: user.email,
    };
  }
}
