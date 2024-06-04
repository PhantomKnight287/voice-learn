import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { createId } from '@paralleldrive/cuid2';
import { prisma } from 'src/db';
import { removePunctuation } from 'src/uitls/string';
import { CreateAnswerDTO } from './answer.dto';

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
      removePunctuation(body.answer).toLowerCase() ===
      removePunctuation(question.correctAnswer).toLowerCase();

    console.log({
      correct,
      answer: removePunctuation(body.answer).toLowerCase(),
      actual: removePunctuation(question.correctAnswer).toLowerCase(),
    });

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
      console.log({ answers });
      if (questions != answers - 1) {
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
    console.log({ questions });
    const user = await prisma.$transaction(async (tx) => {
      await tx.answer.create({
        data: {
          id: `answer_${createId()}`,
          type: correct ? 'correct' : 'incorrect',
          userId,
          questionId,
        },
      });
      if (body.last && correct) {
        questions += 1;
      }
      return await tx.user.update({
        where: { id: userId },
        data: {
          xp: {
            increment: questions * 4,
          },
          lives: {
            decrement: correct === false ? 1 : 0,
          },
          emeralds: {
            increment: body.last ? 1 : 0,
          },
        },
      });
    });
    return {
      id: questionId,
      correct,
      xp: user.xp,
      emeralds: user.emeralds,
      lives: user.lives,
    };
  }
}
