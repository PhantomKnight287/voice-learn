import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { prisma } from 'src/db';
import { removePunctuation } from 'src/utils/string';
import { CreateAnswerDTO } from './dto/answer.dto';
import moment from 'moment';
import { locales } from 'src/constants';

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
        lesson: {
          module: {
            learningPath: {
              userId,
            },
          },
        },
      },
      select: {
        _count: {
          select: { answers: true },
        },
        correctAnswer: true,
        lessonId: true,
      },
    });
    if (!question)
      throw new HttpException('No question found.', HttpStatus.NOT_FOUND);
    const correct =
      removePunctuation(body.answer.trim()).toLowerCase() ===
      removePunctuation(question.correctAnswer.trim()).toLowerCase();

    let questions = 0;
    if (body.last) {
      questions = await prisma.question.count({
        where: {
          lessonId: question.lessonId,
        },
      });
      const answers = await prisma.answer.count({
        where: {
          question: {
            lessonId: question.lessonId,
          },
        },
      });
      // subracting 1 as user is submitting the last answer in this req
      if (questions - 1 != answers) {
        throw new HttpException(
          "Not all questions are answered but 'last' is set to true",
          HttpStatus.CONFLICT,
        );
      }
      questions = await prisma.answer.count({
        where: {
          question: {
            lessonId: question.lessonId,
          },
          type: 'correct',
        },
      });
    }
    const existingAnswer = await prisma.answer.findFirst({
      where: { questionId, userId },
    });
    const user = await prisma.$transaction(async (tx) => {
      if (existingAnswer) {
        await tx.answer.update({
          where: {
            id: existingAnswer.id,
          },
          data: {
            type: correct ? 'correct' : 'incorrect',
            answer: body.answer,
            question: {
              update: {
                lesson: {
                  update: {
                    correctAnswers: { increment: correct ? 1 : 0 },
                    incorrectAnswers: { increment: !correct ? 1 : 0 },
                    completed: body.last,
                    startDate: new Date(body.startDate),
                    endDate: new Date(body.endDate),
                  },
                },
              },
            },
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
        await tx.lesson.update({
          where: { id: question.lessonId },
          data: {
            correctAnswers: { increment: correct ? 1 : 0 },
            incorrectAnswers: { increment: !correct ? 1 : 0 },
            completed: body.last,
            startDate: new Date(body.startDate),
            endDate: new Date(body.endDate),
          },
        });
      }
      if (body.last && correct) {
        questions += 1;
        const currentDateInGMT = moment().utc().startOf('day').toDate();
        const nextDateInGMT = moment()
          .utc()
          .add(1, 'day')
          .startOf('day')
          .toDate();
        const existingStreak = await tx.streak.findFirst({
          where: {
            userId,
            createdAt: {
              gte: currentDateInGMT,
              lt: nextDateInGMT,
            },
          },
        });
        if (!existingStreak)
          await tx.user.update({
            where: { id: userId },
            data: {
              activeStreaks: {
                increment: 1,
              },
              streaks: {
                create: {
                  id: `streak_${createId()}`,
                },
              },
            },
          });
      }
      const user = await tx.user.findFirst({ where: { id: userId } });
      return await tx.user.update({
        where: { id: userId },
        data: {
          xp: {
            increment: questions * 4,
          },
          lives: {
            decrement: user.lives === 0 ? 0 : correct === false ? 1 : 0,
          },
          emeralds: {
            increment: body.last ? 1 : 0,
          },
        },
      });
    });
    let isStreakActive = false;
    if (body.last) {
      const currentDateInGMT = moment().utc().startOf('day').toDate(); // Start of the current day in GMT
      const nextDateInGMT = moment()
        .utc()
        .add(1, 'day')
        .startOf('day')
        .toDate(); // Start of the next day in GMT

      const streak = await prisma.streak.findFirst({
        where: {
          createdAt: {
            gte: currentDateInGMT,
            lt: nextDateInGMT,
          },
          userId: user.id,
        },
      });
      isStreakActive = streak ? true : false;
    }
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
