import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { NotificationsService } from 'src/resources/notifications/notifications.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService, NotificationsService],
})
export class UsersModule {}
