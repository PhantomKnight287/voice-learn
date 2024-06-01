import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';
import { queue } from 'src/services/queue/queue.service';

@Injectable()
export class LessonsService {
  async generateLessonQuestions(lessonId: string, userId: string) {
    const lesson = await prisma.lesson.findFirst({
      where: {
        id: lessonId,
        module: {
          learningPath: {
            userId,
          },
        },
      },
    });
    if (
      lesson.questionsStatus !== 'generating' &&
      lesson.questionsStatus !== 'generated'
    ) {
      await queue.addToQueue({
        id: lesson.id,
        type: 'question',
      });
      await prisma.lesson.update({
        where: { id: lessonId },
        data: { questionsStatus: 'generating' },
      });
    }
    return {
      message: 'Generating',
    };
  }

  async getLessonGenerationStatus(lessonId: string, userId: string) {
    const lesson = await prisma.lesson.findFirst({
      where: {
        id: lessonId,
        module: {
          learningPath: {
            userId,
          },
        },
      },
    });
    if (lesson.questionsStatus == 'not_generated') {
      await this.generateLessonQuestions(lessonId, userId);
    }
    if (lesson.questionsStatus === 'generated')
      return {
        generated: true,
        position: null,
      };
    else {
      const inQueue = await queue.getPositionInQueue({
        id: lessonId,
        type: 'question',
      });
      return {
        position: inQueue == -1 ? null : inQueue,
        generated: false,
      };
    }
  }
}
