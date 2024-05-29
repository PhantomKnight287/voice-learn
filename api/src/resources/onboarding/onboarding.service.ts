import { Injectable } from '@nestjs/common';
import { CompleteOnBoardingDTO } from './dto/complete-onboarding.dto';
import { prisma } from 'src/db';
import { createId } from '@paralleldrive/cuid2';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { CreatePathEvent } from 'src/events';

@Injectable()
export class OnboardingService {
  constructor(protected readonly event: EventEmitter2) {}
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
    this.event.emitAsync(
      'learning_path.create',
      new CreatePathEvent(learningPath.id),
    );
    return learningPath;
  }
}
