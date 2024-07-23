import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { CreateMoreLessonsGenerationDTO } from './dto/generate-more-lessons.dto';
import { prisma } from 'src/db';
import { createId } from '@paralleldrive/cuid2';
import { queue } from 'src/services/queue/queue.service';

@Injectable()
export class GenerationsService {
  async generateMoreLessons(
    body: CreateMoreLessonsGenerationDTO,
    userId: string,
  ) {
    if (body.type === 'lessons' && !body.id)
      throw new HttpException('Please provide Id', HttpStatus.BAD_REQUEST);
    const request = await prisma.generationRequest.findFirst({
      where: {
        type: body.type,
        userId,
      },
    });
    if (request && request.completed == false)
      return {
        id: request.id,
        existing: true,
      };

    if (body.type == 'lessons') {
      const module = await prisma.module.findFirst({
        where: {
          id: body.id,
          learningPath: {
            userId,
          },
        },
      });
      if (!module)
        throw new HttpException('No Module found', HttpStatus.NOT_FOUND);
    }
    const newRequest = await prisma.generationRequest.create({
      data: {
        id: `gr_${createId()}`,
        type: body.type,
        userId,
        prompt: body.prompt,
        ...(body.id
          ? {
              moduleId: body.id,
            }
          : undefined),
      },
    });
    await queue.addToQueue({
      id: newRequest.id,
      type: body.type,
      userId,
    });
    return {
      id: newRequest.id,
      existing: false,
    };
  }
}
