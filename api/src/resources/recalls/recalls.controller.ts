import { Controller, ParseIntPipe, Query } from '@nestjs/common';
import { RecallsService } from './recalls.service';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('recalls')
export class RecallsController {
  constructor(private readonly recallsService: RecallsService) {}

  getStacks(@Query('page', ParseIntPipe) page: number, @Auth() auth: User) {
    return this.recallsService.getStacks(auth.id, page);
  }
}
