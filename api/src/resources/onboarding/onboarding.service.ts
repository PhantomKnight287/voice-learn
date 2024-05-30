import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { CompleteOnBoardingDTO } from './dto/complete-onboarding.dto';
import { prisma } from 'src/db';
import { createId } from '@paralleldrive/cuid2';
import { QueueService } from 'src/services/queue/queue.service';

@Injectable()
export class OnboardingService {
  constructor(protected readonly queue: QueueService) {}
  async completeOnboarding(body: CompleteOnBoardingDTO, userId: string) {
    const learningPath = await prisma.learningPath.create({
      data: {
        id: `learning_path_${createId()}`,
        knowledge: body.knowledge,
        reason: body.reason,
        language: { connect: { id: body.languageId } },
        user: { connect: { id: userId } },
      },
      select: { id: true },
    });
    const analytics = await prisma.analytics.findFirst({
      where: { name: { mode: 'insensitive', equals: body.analytics } },
    });
    if (analytics) {
      await prisma.analytics.update({
        where: { id: analytics.id },
        data: { users: { increment: 1 } },
      });
    } else {
      await prisma.analytics.create({
        data: {
          users: 1,
          name: body.analytics,
        },
      });
    }
    await this.queue.addLearningPathToQueue(learningPath.id);

    return learningPath;
  }

  async getOnBoardingStatus(id: string, userId: string) {
    const onboardingRecord = await prisma.learningPath.findFirst({
      where: { id, userId },
    });
    if (!onboardingRecord)
      throw new HttpException('No path found', HttpStatus.NOT_FOUND);
    if (onboardingRecord.type === 'generated')
      return {
        generated: true,
        position: null,
      };
    else {
      const inQueue = await this.queue.getPositionInQueue(onboardingRecord.id);
      return {
        position: inQueue == -1 ? null : inQueue,
        generated: false,
      };
    }
  }
}