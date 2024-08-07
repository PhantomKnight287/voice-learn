import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateUserDTO } from './dto/update-user-dto';
import { RemoveAvatarDTO } from './dto/remove-avatar.dto';
import { SendNotificationDTO } from './dto/send-notification.dto';

@Controller('admin/users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getUsers(
    @Query('page', ParseIntPipe) page: number,
    @Query('limit', ParseIntPipe) limit: number,
  ) {
    return this.usersService.getUsers(page, limit);
  }

  @Get(':id')
  getUserInfo(@Param('id') id: string) {
    return this.usersService.getUserInfo(id);
  }

  @Patch(':id')
  updateProfile(@Param('id') id: string, @Body() body: UpdateUserDTO) {
    return this.usersService.updateUser(id, body);
  }

  @Delete(':id/avatar')
  removeAvatar(@Param('id') id: string, @Body() body: RemoveAvatarDTO) {
    return this.usersService.removeAvatar(id, body);
  }

  @Post(':id/notification')
  notifyUser(@Param('id') id: string, @Body() body: SendNotificationDTO) {
    return this.usersService.sendNotification(id, body);
  }
}
