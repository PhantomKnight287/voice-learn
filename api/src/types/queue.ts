export type QueueItemType = 'question' | 'learning_path';

export type QueueItemObject = {
  id: string;
  type: QueueItemType;
};
