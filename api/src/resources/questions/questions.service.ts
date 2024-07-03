import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { prisma } from 'src/db';
import { removePunctuation } from 'src/utils/string';
import { CreateAnswerDTO } from './dto/answer.dto';
import moment from 'moment';
import { locales } from 'src/constants';
import { generateTimestamps } from 'src/lib/time';

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
      throw new HttpException('No Lesson found', HttpStatus.NOT_FOUND);
    if (lesson.questionsStatus !== 'generated')
      throw new HttpException(
        'Questions are not generated',
        HttpStatus.NOT_FOUND,
      );

    return {
      questions: lesson.questions,
      locale: locales[lesson.module.learningPath.language.name],
      language: lesson.module.learningPath.language.name,
    };
  }

  async answerQuestion(
    questionId: string,
    userId: string,
    body: CreateAnswerDTO,
  ) {
    const question = await prisma.question.findFirst({
      where: {
        id: questionId,
        lessons: {
          some: {
            module: {
              learningPath: {
                userId,
              },
            },
          },
        },
      },
      select: {
        _count: {
          select: { answers: true },
        },
        correctAnswer: true,
      },
    });

    const lesson = await prisma.lesson.findFirst({
      where: { id: body.lessonId },
    });
    if (!question) {
      throw new HttpException('No question found.', HttpStatus.NOT_FOUND);
    }
    if (!lesson)
      throw new HttpException('No lesson found.', HttpStatus.NOT_FOUND);

    const correct =
      removePunctuation(body.answer.trim()).toLowerCase() ===
      removePunctuation(question.correctAnswer.trim()).toLowerCase();

    if (body.last) {
      const questions = await prisma.question.count({
        where: {
          lessons: {
            some: {
              id: body.lessonId,
            },
          },
        },
      });

      const answers = await prisma.answer.count({
        where: {
          question: {
            lessons: {
              some: {
                id: body.lessonId,
              },
            },
          },
        },
      });
      // subtracting one cause the last answer will be sent in current request
      if (questions - 1 != answers && lesson.name !== 'Mistake Correction') {
        throw new HttpException(
          "Not all questions are answered but 'last' is set to true",
          HttpStatus.CONFLICT,
        );
      }
    }
    const user = await prisma.$transaction(async (tx) => {
      const existingAnswer = await tx.answer.findFirst({
        where: { questionId, userId },
      });

      if (existingAnswer) {
        await tx.answer.update({
          where: { id: existingAnswer.id },
          data: {
            type: correct ? 'correct' : 'incorrect',
            answer: body.answer,
          },
        });
      } else {
        await tx.answer.create({
          data: {
            id: `answer_${createId()}`,
            type: correct ? 'correct' : 'incorrect',
            userId,
            questionId,
            answer: body.answer,
          },
        });
      }

      if (body.last) {
        const incorrectAnswersCount = await tx.answer.count({
          where: {
            question: {
              lessons: {
                some: {
                  id: body.lessonId,
                },
              },
            },
            type: 'incorrect',
          },
        });
        const correctAnswersCount = await tx.answer.count({
          where: {
            question: {
              lessons: {
                some: {
                  id: body.lessonId,
                },
              },
            },
            type: 'correct',
          },
        });
        const lesson = await tx.lesson.update({
          where: { id: body.lessonId },
          data: {
            correctAnswers: {
              increment: correctAnswersCount + (correct ? 1 : 0),
            },
            incorrectAnswers: {
              increment: incorrectAnswersCount - 1 + (!correct ? 1 : 0),
            },
            completed: body.last,
            startDate: new Date(body.startDate),
            endDate: new Date(body.endDate),
          },
          include: {
            module: {
              include: {
                learningPath: true,
              },
            },
          },
        });
        await tx.user.update({
          where: { id: userId },
          data: {
            xp: {
              increment:
                correctAnswersCount +
                (correct ? 1 : 0) * (lesson ? lesson.xpPerQuestion : 4),
            },
            xpHistory: {
              create: {
                earned:
                  correctAnswersCount +
                  (correct ? 1 : 0) * (lesson ? lesson.xpPerQuestion : 4),
                id: `xp_${createId()}`,
                language: {
                  connect: {
                    id: lesson.module.learningPath.languageId,
                  },
                },
              },
            },
          },
        });
      }

      const { currentDateInGMT, nextDateInGMT } = generateTimestamps();

      const existingStreak = await tx.streak.findFirst({
        where: {
          userId,
          createdAt: {
            gte: currentDateInGMT,
            lt: nextDateInGMT,
          },
        },
      });

      const user = await tx.user.findFirst({ where: { id: userId } });

      if (!existingStreak && body.last) {
        await tx.user.update({
          where: { id: userId },
          data: {
            activeStreaks: {
              increment: 1,
            },
            longestStreak: {
              increment: user.activeStreaks + 1 > user.longestStreak ? 1 : 0,
            },
            streaks: {
              create: {
                id: `streak_${createId()}`,
              },
            },
          },
        });
      }

      const lesson = await prisma.lesson.findFirst({
        where: { id: body.lessonId },
        include: {
          module: {
            include: {
              learningPath: true,
            },
          },
        },
      });

      return await tx.user.update({
        where: { id: userId },
        data: {
          lives: {
            decrement:
              user.lives === 0
                ? 0
                : correct === false
                  ? user.tier === 'free'
                    ? 1
                    : 0
                  : 0,
          },
          emeralds: {
            increment: body.last ? (lesson ? lesson.emeralds : 1) : 0,
          },
        },
      });
    });
    const { currentDateInGMT, nextDateInGMT } = generateTimestamps();

    const streak = await prisma.streak.findFirst({
      where: {
        createdAt: {
          gte: currentDateInGMT,
          lt: nextDateInGMT,
        },
        userId: user.id,
      },
    });

    const isStreakActive = streak ? true : false;

    return {
      id: questionId,
      correct,
      xp: user.xp,
      emeralds: user.emeralds,
      lives: user.lives,
      streaks: user.activeStreaks,
      isStreakActive,
    };
  }
}
