import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';
import { UpdateUserDTO } from './dto/update-user-dto';
import { NotificationsService } from 'src/resources/notifications/notifications.service';
import { RemoveAvatarDTO } from './dto/remove-avatar.dto';
import { SendNotificationDTO } from './dto/send-notification.dto';

@Injectable()
export class UsersService {
  constructor(private readonly notificationService: NotificationsService) {}
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
        streakShields: true,
      },
    });
  }

  async updateUser(id: string, body: UpdateUserDTO) {
    const user = await prisma.user.findFirst({
      where: {
        id,
      },
    });
    if (!user) throw new HttpException('No user found', HttpStatus.NOT_FOUND);
    const { updateReasonDescription, updateReasonTitle, ...rest } = body;

    const updatedUser = await prisma.user.update({
      where: {
        id: user.id,
      },
      data: rest,
    });
    await this.notificationService.createNotification(user.id, {
      description: updateReasonDescription,
      title: updateReasonTitle,
      type: 'ALERT',
    });
    return {
      message: 'Updated',
    };
  }
  async removeAvatar(id: string, body: RemoveAvatarDTO) {
    const user = await prisma.user.findFirst({
      where: {
        id,
      },
    });
    if (!user) throw new HttpException('No user found', HttpStatus.NOT_FOUND);
    await prisma.user.update({
      where: { id: user.id },
      data: { avatar: null },
    });
    const res = await this.notificationService.createNotification(user.id, {
      title: body.updateReasonTitle,
      description: body.updateReasonDescription,
      type: 'ALERT',
    });
    return {
      message: 'Avatar removed',
    };
  }

  async sendNotification(id: string, body: SendNotificationDTO) {
    const user = await prisma.user.findFirst({
      where: {
        id,
      },
    });
    if (!user) throw new HttpException('No user found', HttpStatus.NOT_FOUND);

    const res = await this.notificationService.createNotification(user.id, {
      title: body.title,
      description: body.description,
      type: body.type,
    });
    return {
      message: 'User notified',
    };
  }
}
