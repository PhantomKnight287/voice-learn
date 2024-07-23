import {
  Body,
  Controller,
  Delete,
  Get,
  ParseIntPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { SetupNotificationsDTO } from './dto/setup-notification.dto';
import { prisma } from 'src/db';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post()
  async setupNotifications(
    @Body() body: SetupNotificationsDTO,
    @Auth() user: User,
  ) {
    await prisma.user.update({
      where: { id: user.id },
      data: { notificationToken: body.id },
    });
    return {
      id: user.id,
    };
  }

  @Delete()
  async clearNotifications(@Auth() user: User) {
    await prisma.user.update({
      where: { id: user.id },
      data: { notificationToken: null },
    });
    return {
      id: user.id,
    };
  }

  @Get()
  getNotifications(
    @Auth() user: User,
    @Query('page', ParseIntPipe) page: number,
    @Query('limit', ParseIntPipe) limit: number,
  ) {
    return this.notificationsService.getNotifications(user.id, page, limit);
  }
  @Get('unread-count')
  async getUnreadNotificationsCount(@Auth() user: User) {
    return this.notificationsService.getUnreadNotificationsCount(user.id);
  }

  @Patch('read')
  async markAllAsRead(@Auth() auth: User) {
    return this.notificationsService.markAllAsRead(auth.id);
  }
}
