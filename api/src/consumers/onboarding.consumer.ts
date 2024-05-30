import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { CreatePathEvent } from 'src/events';
import { QueueService } from 'src/services/queue/queue.service';

@Injectable()
export class OnboardingQueueConsumer {
  constructor(
    protected queue: QueueService,
    protected event: EventEmitter2,
  ) {
    this.processQueue();
  }

  async processQueue() {
    for await (const request of this.queue.getLearningPathToGenerate()) {
      if (request) {
        await this.event.emitAsync(
          'learning_path.create',
          new CreatePathEvent(request),
        );
      }
    }
  }
}
