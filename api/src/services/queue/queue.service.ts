import { Redis } from '@upstash/redis';

export class QueueService extends Redis {
  protected readonly queue_name = 'learning_path::generate::queue';
  private requestsThisMinute = 0;
  private readonly maxRequestsPerMinute = 15;

  constructor() {
    super({
      url: process.env['REDIS_HOST'],
      token: process.env['REDIS_PASSWORD'],
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
          yield null;
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

  async getPositionInQueue(id: string): Promise<number | null> {
    const position = await this.lpos(this.queue_name, id);
    return position !== null ? position + 1 : -1;
  }
  private resetRequestQuota() {
    this.requestsThisMinute = 0;
  }
}

export const queue = new QueueService();
