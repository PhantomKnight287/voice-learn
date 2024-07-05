import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { locales } from 'src/constants';
import { prisma } from 'src/db';
import { generateTimestamps } from 'src/lib/time';
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

    const { currentDateInGMT, nextDateInGMT } = generateTimestamps();

    const questionIds = lesson.questions.map((q) => q.id);
    const answers = await prisma.answer.groupBy({
      by: 'type',
      _count: {
        type: true,
      },
      where: {
        questionId: {
          in: questionIds,
        },
      },
    });

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
      correctAnswers:
        answers.find((item) => item.type === 'correct')?._count.type ||
        lesson.correctAnswers,
      incorrectAnswers:
        answers.find((item) => item.type === 'incorrect')?._count.type ||
        lesson.incorrectAnswers,
      xpEarned:
        (answers.find((item) => item.type === 'correct')?._count.type ||
          lesson.correctAnswers) * 4,
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

  async getLessons(userId: string, moduleId: string) {
    const module = await prisma.module.findFirst({
      where: { id: moduleId, learningPath: { userId } },
    });
    if (!module)
      throw new HttpException('No module found', HttpStatus.NOT_FOUND);
    const lessons = await prisma.lesson.findMany({
      where: { moduleId },
      omit: {
        createdAt: true,
        endDate: true,
        startDate: true,
        moduleId: true,
        updatedAt: true,
      },
      orderBy: [
        {
          createdAt: 'asc',
        },
      ],
    });
    return lessons;
  }

  async getLessonDetailedStats(userId: string, id: string) {
    const lesson = await prisma.lesson.findFirst({
      where: {
        OR: [
          {
            questions: {
              some: {
                id: id,
              },
            },
          },
          {
            id: id,
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
            answers: true,
          },
        },
        module: {
          select: {
            learningPath: {
              select: {
                language: {
                  select: {
                    name: true,
                  },
                },
              },
            },
          },
        },
      },
    });
    if (!lesson)
      throw new HttpException('No lesson found.', HttpStatus.NOT_FOUND);
    if (!lesson.completed)
      throw new HttpException(
        'Please complete the lesson before review.',
        HttpStatus.CONFLICT,
      );
    return {
      ...lesson,
      locale: locales[lesson.module.learningPath.language.name],
    };
  }
}
