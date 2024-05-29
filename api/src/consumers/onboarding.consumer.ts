import {
  Processor,
  Process,
  OnQueueActive,
  OnQueueCompleted,
} from '@nestjs/bull';
import { Job } from 'bull';
import { Logger } from '@nestjs/common';
import { ONBOARDING_QUEUE } from 'src/constants';

@Processor(ONBOARDING_QUEUE)
export class OnboardingQueueConsumer {
  @Process({
    concurrency: 1,
  })
  async processData() {
    await new Promise((resolve, reject) => {
      try {
        setTimeout(
          () => {
            resolve('Data processed');
          },
          5000 + Math.floor(Math.random() * 5000),
        );
      } catch (error) {
        reject(error);
      }
    });

    return { done: true };
  }

  @OnQueueActive()
  onActive(job: Job<unknown>) {
    Logger.log(`Starting job ${job.id} : ${job.data['id']}`);
  }

  @OnQueueCompleted()
  onCompleted(job: Job<unknown>) {
    // Log job completion status
    Logger.log(`Job ${job.id} has been finished`);
  }
}
