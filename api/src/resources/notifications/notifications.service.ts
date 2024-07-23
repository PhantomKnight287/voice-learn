import { Injectable } from '@nestjs/common';
import { prisma } from 'src/db';
import { CreateNoteDTO } from '../recalls/dto/create-note.dto';
import { onesignal } from 'src/constants';
import { CreateNotificationDTO } from './dto/create-notification.dto';

@Injectable()
export class NotificationsService {
  async getNotifications(userId: string, page: number, limit: number = 20) {
    const notifications = await prisma.notification.paginate({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      page,
      limit,
      select: {
        id: true,
        createdAt: true,
        description: true,
        title: true,
        read: true,
        type: true,
      },
    });
    const hasUnread = notifications.result.filter((d) => !d.read);

    return {
      notifications: notifications.result,
      hasUnread: hasUnread.length > 0,
    };
  }

  async getUnreadNotificationsCount(userId: string) {
    const count = await prisma.notification.count({
      where: { userId, read: false },
    });
    return {
      count,
    };
  }
  async createNotification(userId: string, body: CreateNotificationDTO) {
    const user = await prisma.user.findFirst({ where: { id: userId } });
    if (!user) return;
    await prisma.notification.create({
      data: {
        description: body.description,
        title: body.title,
        userId,
        type: body.type,
      },
    });
    if (user.notificationToken) {
      const res = await onesignal.createNotification({
        app_id: process.env.ONESIGNAL_APP_ID,
        name: body.title,
        contents: {
          en: body.description,
        },
        headings: {
          en: body.title,
        },
        include_subscription_ids: [user.notificationToken],
      });
      console.log(res);
    }
  }

  async markAllAsRead(userId: string) {
    const count = await prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
    return count;
  }
}
