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
    const request = await prisma.generationRequest.findFirst({
      where: {
        type: 'modules',
        userId,
      },
    });
    if (request && request.completed == false)
      return {
        id: request.id,
        existing:true,
      };

    const newRequest = await prisma.generationRequest.create({
      data: {
        id: `generation_request_${createId()}`,
        type: 'modules',
        userId,
        prompt: body.prompt,
      },
    });
    await queue.addToQueue({
      id: newRequest.id,
      type: 'modules',
    });
    return {
      id: newRequest.id,
      existing:false,
    };
  }
}
