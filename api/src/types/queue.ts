export type QueueItemType =
  | 'question'
  | 'learning_path'
  | 'modules'
  | 'lessons';

export type QueueItemObject =
  | {
      id: string;
      type: QueueItemType;
    }
  | {
      id: string;
      type: 'chat';
      messageId: string;
    };
