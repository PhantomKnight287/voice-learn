import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { prisma } from 'src/db';

@Injectable()
export class QuestionsService {
  async getLessonQuestions(lessonId: string, userId: string) {
    const lesson = await prisma.lesson.findFirst({
      where: { id: lessonId, module: { learningPath: { userId } } },
      include: {
        questions: {
          omit: {
            updatedAt: true,
          },
        },
      },
    });
    if (!lesson)
      throw new HttpException('No Lesson found', HttpStatus.NOT_FOUND);
    if (lesson.questionsStatus !== 'generated')
      throw new HttpException(
        'Questions are not generated',
        HttpStatus.NOT_FOUND,
      );

    return lesson.questions;
  }
}
