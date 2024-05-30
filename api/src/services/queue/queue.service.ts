import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Redis } from '@upstash/redis';

@Injectable()
export class QueueService extends Redis {
  protected readonly queue_name = 'learning_path::generate::queue';
  private requestQueue: Array<() => void> = [];
  private requestsThisMinute = 0;
  private readonly maxRequestsPerMinute = 15;

  constructor(protected readonly config: ConfigService) {
    super({
      url: config.getOrThrow('REDIS_HOST'),
      token: config.getOrThrow('REDIS_PASSWORD'),
    });

    setInterval(() => this.resetRequestQuota(), 60000);
  }

  async addLearningPathToQueue(id: string): Promise<void> {
    await this.rpush(this.queue_name, id);
  }
  async *getLearningPathToGenerate(): AsyncGenerator<string | null> {
    while (true) {
      if (this.requestsThisMinute < this.maxRequestsPerMinute) {
        const item = await this.lpop<string | null>(this.queue_name);
        if (item === null) {
          break;
        }
        this.requestsThisMinute++;
        yield item;
      } else {
        // Wait until the quota resets
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }
    }
  }
  async addLearningPathToQueueWithPriority(id: string): Promise<void> {
    await this.lpush(this.queue_name, id);
  }
  private processQueue() {
    if (
      this.requestsThisMinute < this.maxRequestsPerMinute &&
      this.requestQueue.length > 0
    ) {
      const request = this.requestQueue.shift();
      if (request) {
        this.requestsThisMinute++;
        request();
      }
    }
  }
  async getPositionInQueue(id: string): Promise<number | null> {
    const position = await this.lpos(this.queue_name, id);
    return position !== null ? position : -1;
  }
  private resetRequestQuota() {
    this.requestsThisMinute = 0;
    this.processQueue();
  }
}
