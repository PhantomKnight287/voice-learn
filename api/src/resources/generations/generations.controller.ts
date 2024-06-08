import { Body, Controller, Post } from '@nestjs/common';
import { GenerationsService } from './generations.service';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';
import { CreateMoreLessonsGenerationDTO } from './dto/generate-more-lessons.dto';

@Controller('generations')
export class GenerationsController {
  constructor(private readonly generationsService: GenerationsService) {}

  @Post()
  createNewLessonGeneration(
    @Auth() auth: User,
    @Body() body: CreateMoreLessonsGenerationDTO,
  ) {
    return this.generationsService.generateMoreLessons(body, auth.id);
  }
}
