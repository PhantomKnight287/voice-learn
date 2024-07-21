import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { prisma } from 'src/db';
import { removePunctuation } from 'src/utils/string';
import { CreateAnswerDTO } from './dto/answer.dto';
import moment from 'moment';
import { locales, testSentences } from 'src/constants';
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
                    id:true,
                    flagUrl:true,
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
      language: lesson.module.learningPath.language,
      sentence: testSentences[lesson.module.learningPath.language.name],
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
      include: {
        module: {
          include: {
            learningPath: true,
          },
        },
      },
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
              increment: correctAnswersCount,
            },
            incorrectAnswers: {
              increment: incorrectAnswersCount,
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
                correctAnswersCount * (lesson ? lesson.xpPerQuestion : 4),
            },
            xpHistory: {
              create: {
                earned:
                  correctAnswersCount * (lesson ? lesson.xpPerQuestion : 4),
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
        const allIncorrectQuestions = await tx.question.findMany({
          where: {
            lessons: {
              some: {
                id: body.lessonId,
              },
            },
            answers: {
              every: {
                type: 'incorrect',
              },
            },
          },
          select: {
            id: true,
          },
        });
        if (allIncorrectQuestions.length > 0) {
          const olderCorrectionModule = await tx.lesson.findFirst({
            where: {
              name: 'Mistake Correction',
              emeralds: 0,
              xpPerQuestion: 0,
              moduleId: lesson.moduleId,
            },
          });
          const correctionModule =
            olderCorrectionModule ??
            (await tx.lesson.create({
              data: {
                id: `lesson_${createId()}`,
                name: 'Mistake Correction',
                completed: false,
                questionsCount: allIncorrectQuestions.length,
                questionsStatus: 'generated',
                emeralds: 0,
                xpPerQuestion: 0,
                module: {
                  connect: {
                    id: lesson.moduleId,
                  },
                },
              },
            }));
          for (const ques of allIncorrectQuestions) {
            await tx.question.update({
              where: { id: ques.id },
              data: {
                lessons: {
                  connect: {
                    id: correctionModule.id,
                  },
                },
              },
            });
          }
        }
      }

      const user = await tx.user.findFirst({ where: { id: userId } });
      const { currentDate,currentDateStart } = generateTimestamps(
        user.timezone,
      );

      const existingStreak = await tx.streak.findFirst({
        where: {
          userId,
          createdAt: {
            gte: currentDateStart,
            lte: currentDate,
          },
        },
      });

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
    const { currentDate,currentDateStart } = generateTimestamps(
      user.timezone,
    );

    const streak = await prisma.streak.findFirst({
      where: {
        createdAt: {
          gte: currentDateStart,
          lte: currentDate,
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
