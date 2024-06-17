import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { queue } from 'src/services/queue/queue.service';

@Injectable()
export class OnboardingQueueConsumer {
  constructor(protected event: EventEmitter2) {
    this.processQueue();
  }

  async processQueue() {
    for await (const request of queue.getQueueItem()) {
      if (request) {
        await this.event.emitAsync('queue.handle', request);
      }
    }
  }
}
