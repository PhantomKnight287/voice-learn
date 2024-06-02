import { Controller, Get, Param } from '@nestjs/common';
import { QuestionsService } from './questions.service';
import { ApiHeader, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('questions')
@ApiTags('Questions')
@ApiHeader({
  name: 'Authorization',
  description: 'Token',
  allowEmptyValue: false,
  required: true,
})
export class QuestionsController {
  constructor(private readonly questionsService: QuestionsService) {}

  @ApiOperation({
    summary: 'Get questions of Lesson',
    description: 'Get questions of Lesson',
  })
  @ApiParam({
    name: 'id',
    description: 'The lesson id',
  })
  @Get(':id')
  getQuestions(@Param('id') id: string, @Auth() user: User) {
    return this.questionsService.getLessonQuestions(id, user.id);
  }
}
