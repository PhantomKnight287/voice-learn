import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class UsersService {
  async getUsers(page = 1, limit = 50) {
    const data = await prisma.user.paginate({
      page,
      limit,
      select: {
        name: true,
        avatar: true,
        avatarHash: true,
        createdAt: true,
        _count: true,
        activeStreaks: true,
        email: true,
        id: true,
        lives: true,
        emeralds: true,
        tier: true,
        timezone: true,
        timeZoneOffSet: true,
        xp: true,
      },
    });
    return {
      results: data.result,
      pages: data.totalPages,
    };
  }
  async getUserInfo(userId: string) {
    return await prisma.user.findFirst({
      where: {
        id: userId,
      },
      omit: {
        password: true,
        activeStreaks: true,
        chatScreenTutorialShown: true,
        homeScreenTutorialShown: true,
        longestStreak: true,
        notificationToken: true,
        streakShields:true,
      },
    });
  }
}
