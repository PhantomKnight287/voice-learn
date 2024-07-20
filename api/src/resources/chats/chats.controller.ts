import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { ChatsService } from './chats.service';
import {
  ApiHeader,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';
import { CreateChatDTO } from './dto/create-chat.dto';

@Controller('chats')
@ApiTags('Chats')
@ApiHeader({
  name: 'Authorization',
  description: 'Token',
  allowEmptyValue: false,
  required: true,
})
export class ChatsController {
  constructor(private readonly chatsService: ChatsService) {}

  @ApiOperation({})
  @Get()
  @ApiQuery({
    name: 'page',
    type: Number,
    required: false,
  })
  getChats(@Auth() auth: User, @Query('page') page?: string) {
    return this.chatsService.getMyChats(auth.id, page);
  }

  @ApiOperation({})
  @Post()
  @ApiQuery({
    name: 'page',
    type: Number,
    required: false,
  })
  createChat(@Auth() auth: User, @Body() body: CreateChatDTO) {
    return this.chatsService.createChat(body, auth.id);
  }

  @ApiOperation({})
  @Get(':id')
  @ApiParam({
    name: 'id',
    type: String,
    required: true,
  })
  getChatInfo(@Auth() auth: User, @Param('id') id: string) {
    return this.chatsService.getChatInfo(auth.id, id);
  }

  @ApiOperation({})
  @Get(':id/messages')
  @ApiParam({
    name: 'id',
    type: String,
    required: true,
  })
  @ApiQuery({
    name: 'id',
    type: String,
    required: false,
  })
  getChatMessages(
    @Auth() auth: User,
    @Param('id') id: string,
    @Query('id') lastMessageId: string,
  ) {
    if (lastMessageId)
      return this.chatsService.fetchOlderMessages(auth.id, id, lastMessageId);
    else return this.chatsService.getLatestMessages(auth.id, id);
  }

  @Delete(':id')
  deleteChat(@Auth() auth: User, @Param('id') id: string) {
    return this.chatsService.deleteChat(auth.id, id);
  }
}
