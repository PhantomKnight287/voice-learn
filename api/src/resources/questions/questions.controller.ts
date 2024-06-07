import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { QuestionsService } from './questions.service';
import {
  ApiHeader,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';
import { CreateAnswerDTO } from './dto/answer.dto';

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

  @ApiOperation({
    summary: 'Answer a question',
    description: 'Answer a question',
  })
  @ApiOkResponse({ schema: { example: { id: 'string', correct: 'boolean' } } })
  @ApiNotFoundResponse({ schema: { example: { message: 'string' } } })
  @ApiParam({
    name: 'id',
    description: 'The id of question',
  })
  @Post(':id/answer')
  answerQuestion(
    @Body() body: CreateAnswerDTO,
    @Auth() user: User,
    @Param('id') id: string,
  ) {
    return this.questionsService.answerQuestion(id, user.id, body);
  }
}
