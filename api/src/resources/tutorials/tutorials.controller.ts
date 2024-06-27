import { Controller, Get, Put } from '@nestjs/common';
import { TutorialsService } from './tutorials.service';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('tutorials')
export class TutorialsController {
  constructor(private readonly tutorialsService: TutorialsService) {}

  @Get()
  getTutorialsStatus(@Auth() auth: User) {
    return this.tutorialsService.getTutorialsStatus(auth.id);
  }

  @Put('home')
  markHomeScreenTutorialAsShown(@Auth() auth: User) {
    return this.tutorialsService.markHomeScreenTutorialShown(auth.id);
  }

  @Put('chat')
  markChatScreenTutorialAsShown(@Auth() auth: User) {
    return this.tutorialsService.markChatScreenTutorialAsShown(auth.id);
  }
}
