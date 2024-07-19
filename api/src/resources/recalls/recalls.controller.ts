import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
} from '@nestjs/common';
import { RecallsService } from './recalls.service';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';
import { CreateStackDTO } from './dto/create-stack.dto';
import { CreateNoteDTO } from './dto/create-note.dto';

@Controller('recalls')
export class RecallsController {
  constructor(private readonly recallsService: RecallsService) {}

  @Get('stacks')
  getStacks(@Query('page', ParseIntPipe) page: number, @Auth() auth: User) {
    return this.recallsService.getStacks(auth.id, page);
  }

  @Post('stacks')
  createStack(@Body() body: CreateStackDTO, @Auth() auth: User) {
    return this.recallsService.createStack(body, auth.id);
  }

  @Post(':id/notes')
  createNote(
    @Body() body: CreateNoteDTO,
    @Auth() auth: User,
    @Param('id') id: string,
  ) {
    return this.recallsService.createNote(body, id, auth.id);
  }

  @Delete(':id')
  deleteStack(@Auth() auth: User, @Param('id') id: string) {
    return this.recallsService.deleteStack(id, auth.id);
  }

  @Get(':id/notes')
  getNotes(
    @Query('page', ParseIntPipe) page: number,
    @Auth() auth: User,
    @Param('id') id: string,
  ) {
    return this.recallsService.listNotes(id, auth.id, page);
  }

  @Get('stacks/all')
  getAllStacks(@Auth() auth: User) {
    return this.recallsService.getStackNames(auth.id);
  }

  @Get('notes/:id')
  getNote(@Auth() auth: User, @Param('id') id: string) {
    return this.recallsService.getNoteInfo(id, auth.id);
  }
  @Delete('notes/:id')
  deleteNote(@Auth() auth: User, @Param('id') id: string) {
    return this.recallsService.deleteNote(id, auth.id);
  }
}
