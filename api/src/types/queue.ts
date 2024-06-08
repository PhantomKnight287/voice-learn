export type QueueItemType = 'question' | 'learning_path' | 'modules';

export type QueueItemObject = {
  id: string;
  type: QueueItemType;
};
