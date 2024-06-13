import { Redis } from '@upstash/redis';
import { QueueItemObject } from 'src/types/queue';

export class QueueService extends Redis {
  protected readonly queue_name = 'gemini::queue::dev';
  private requestsThisMinute = 0;
  private readonly maxRequestsPerMinute = 15;

  constructor() {
    super({
      url: process.env['REDIS_HOST'],
      token: process.env['REDIS_PASSWORD'],
    });

    setInterval(() => this.resetRequestQuota(), 60000);
  }

  async addToQueue(props: QueueItemObject): Promise<void> {
    await this.rpush(this.queue_name, JSON.stringify(props));
  }
  async *getQueueItem(): AsyncGenerator<QueueItemObject | null> {
    while (true) {
      if (this.requestsThisMinute < this.maxRequestsPerMinute) {
        const item = await this.lpop<string | null>(this.queue_name);
        if (item === null) {
          yield null;
          continue;
        }
        this.requestsThisMinute++;
        yield item as unknown as QueueItemObject;
      } else {
        // Wait until the quota resets
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }
    }
  }
  async addToQueueWithPriority(props: QueueItemObject): Promise<void> {
    await this.lpush(this.queue_name, JSON.stringify(props));
  }

  async getPositionInQueue(id: QueueItemObject): Promise<number | null> {
    const position = await this.lpos(this.queue_name, JSON.stringify(id));
    return position !== null ? position + 1 : -1;
  }
  private resetRequestQuota() {
    this.requestsThisMinute = 0;
  }
}

export const queue = new QueueService();
