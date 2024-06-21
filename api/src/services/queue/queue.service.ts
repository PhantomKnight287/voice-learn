import { Redis } from '@upstash/redis';
import { QueueItemObject } from 'src/types/queue';

class QueueService extends Redis {
  protected readonly queue_name =
    process.env.DEV === 'true' ? 'gemini::queue::_dev' : 'gemini::queue';
  private requestsThisMinute = 0;
  private readonly maxRequestsPerMinute = 15;
  private hasMoreInQueue = true;
  constructor() {
    super({
      url: process.env['REDIS_HOST'],
      token: process.env['REDIS_PASSWORD'],
    });
    setInterval(() => this.resetRequestQuota(), 60000);
  }

  async addToQueue(props: QueueItemObject) {
    this.hasMoreInQueue = true;
    return await this.rpush(this.queue_name, JSON.stringify(props));
  }
  async *getQueueItem(): AsyncGenerator<QueueItemObject | null> {
    while (true) {
      if (
        this.requestsThisMinute < this.maxRequestsPerMinute &&
        this.hasMoreInQueue
      ) {
        const item = await this.lpop<string | null>(this.queue_name);
        if (item === null) {
          yield null;
          this.hasMoreInQueue = false;
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
  async addToQueueWithPriority(props: QueueItemObject) {
    this.hasMoreInQueue = true;
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
