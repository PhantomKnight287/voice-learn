import { Body, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { ReportQuestionDTO } from './dto/report-question.dto';
import { prisma } from 'src/db';

@Injectable()
export class ReportsService {
  async reportQuestion(
    @Body() body: ReportQuestionDTO,
    questionId: string,
    userId: string,
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
      include: {
        report: true,
      },
    });
    if (!question)
      throw new HttpException('No Question found.', HttpStatus.NOT_FOUND);
    if (question.report?.id)
      throw new HttpException(
        'This question is already reported',
        HttpStatus.CONFLICT,
      );
    const report = await prisma.report.create({
      data: {
        title: body.title,
        content: body.content,
        author: {
          connect: {
            id: userId,
          },
        },
        question: {
          connect: {
            id: questionId,
          },
        },
      },
    });
    return {
      id: report.id,
    };
  }
}
