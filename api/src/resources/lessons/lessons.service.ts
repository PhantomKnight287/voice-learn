import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import moment from 'moment';
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

  async getLessonCompletionStats(questionId: string, userId: string) {
    const lesson = await prisma.lesson.findFirst({
      where: {
        OR: [
          {
            questions: {
              some: {
                id: questionId,
              },
            },
          },
          {
            id: questionId,
          },
        ],
        module: {
          learningPath: {
            userId,
          },
        },
      },
      include: {
        questions: {
          include: {
            answers: {
              select: {
                type: true,
                answer: true,
              },
            },
          },
        },
      },
    });
    if (!lesson)
      throw new HttpException('No lesson found', HttpStatus.NOT_FOUND);

    const currentDateInGMT = moment().utc().startOf('day').toDate(); // Start of the current day in GMT
    const nextDateInGMT = moment().utc().add(1, 'day').startOf('day').toDate(); // Start of the next day in GMT

    const streak = await prisma.streak.findFirst({
      where: {
        createdAt: {
          gte: currentDateInGMT,
          lt: nextDateInGMT,
        },
        userId: userId,
      },
      include: {
        user: true,
      },
    });

    const user = await prisma.user.findFirst({
      where: {
        id: userId,
      },
    });
    return {
      correctAnswers: lesson.correctAnswers,
      incorrectAnswers: lesson.incorrectAnswers,
      xpEarned: lesson.correctAnswers * 4,
      emeraldsEarned: 1,
      startDate: lesson.startDate,
      endDate: lesson.endDate,
      user: {
        xp: user.xp,
        emeralds: user.emeralds,
        lives: user.lives,
        isStreakActive: streak ? true : false,
        streaks: user.activeStreaks,
      },
    };
  }
}
