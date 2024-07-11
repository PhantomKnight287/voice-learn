import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';
import { UpdateProfileDTO } from './dto/update-profile.dto';
import { createHash } from 'crypto';

@Injectable()
export class ProfileService {
  async getMyProfile(userId: string, own = true) {
    const user = await prisma.user.findFirst({
      where: {
        id: userId,
      },
      omit: {
        password: true,
        ...(own == false
          ? { email: true, notificationToken: true }
          : undefined),
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

    const xpHistory = await prisma.$queryRaw`
    SELECT
      to_char("createdAt", 'YYYY-MM-DD') AS "date",
      SUM("earned") AS "earned"
    FROM
      "XP"
    WHERE
      "userId" = ${userId}
    GROUP BY
      to_char("createdAt", 'YYYY-MM-DD')
    ORDER BY
      "date";
  `;
    return { ...user, xpHistory };
  }
  async getUserProfile(userId: string) {
    const user = await this.getMyProfile(userId, false);
    if (!user) throw new HttpException('No user found.', HttpStatus.NOT_FOUND);

    return { ...user };
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
