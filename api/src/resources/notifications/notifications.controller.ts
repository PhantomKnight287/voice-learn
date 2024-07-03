import { Body, Controller, Delete, Post } from '@nestjs/common';
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
}
