import { Controller, Get, Param, Post } from '@nestjs/common';
import { LessonsService } from './lessons.service';
import {
  ApiHeader,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { Auth } from 'src/decorators/auth/auth.decorator';
import { User } from '@prisma/client';

@Controller('lessons')
@ApiTags('Lessons')
@ApiHeader({
  name: 'Authorization',
  description: 'Token',
  allowEmptyValue: false,
  required: true,
})
export class LessonsController {
  constructor(private readonly lessonsService: LessonsService) {}

  @ApiOperation({
    summary: 'Get queue status',
    description: 'Get queue status',
  })
  @ApiOkResponse({
    schema: {
      example: {
        generated: 'boolean',
        position: 'number | null',
      },
    },
  })
  @ApiParam({
    name: 'id',
    description: 'The id of lesson',
  })
  @Get(':id')
  getQuestionsGenerationStatus(@Param('id') id: string, @Auth() user: User) {
    return this.lessonsService.getLessonGenerationStatus(id, user.id);
  }

  @ApiOperation({
    description: 'Generate Questions',
    summary: 'Generate Questions',
  })
  @ApiParam({
    name: 'id',
    description: 'The id of lesson',
  })
  @Post(':id')
  generateQuestions(@Auth() user: User, @Param('id') id: string) {
    return this.lessonsService.generateLessonQuestions(id, user.id);
  }

  @ApiOperation({})
  @ApiParam({ name: 'id', description: 'The id of question/lesson' })
  @Get(':id/stats')
  getLessonStats(@Auth() user: User, @Param('id') id: string) {
    return this.lessonsService.getLessonCompletionStats(id, user.id);
  }

  @ApiOperation({})
  @ApiParam({ name: 'id', description: 'The id of module' })
  @Get(':id/lessons')
  getModuleLessons(@Auth() user: User, @Param('id') id: string) {
    return this.lessonsService.getLessons(user.id, id);
  }

  @Get(':id/detailed-stats')
  getDetailedLessonStats(@Auth() user: User, @Param('id') id: string) {
    return this.lessonsService.getLessonDetailedStats(user.id, id);
  }
}
