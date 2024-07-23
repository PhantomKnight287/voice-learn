import { NotificationType } from '@prisma/client';

export type QueueItemType =
  | 'question'
  | 'learning_path'
  | 'modules'
  | 'lessons';

export type QueueItemObject = { retries?: number; userId: string } & (
  | {
      id: string;
      type: QueueItemType;
    }
  | {
      id: string;
      type: 'chat';
      messageId: string;
    }
);

export const failureNotifications: {
  [key in QueueItemType | 'chat']: {
    title: string;
    description: string;
    type: NotificationType;
  };
} = {
  question: {
    title: 'Questions Generation Failed',
    description:
      'The system could not generate your question after multiple attempts.',
    type: NotificationType.ALERT,
  },
  learning_path: {
    title: 'Learning Path Generation Error',
    description: 'The learning path generation failed after multiple retries.',
    type: NotificationType.ALERT,
  },
  modules: {
    title: 'Modules Generation Error',
    description: 'The module could not be generated after several retries.',
    type: NotificationType.ALERT,
  },
  lessons: {
    title: 'Lessons Generation Failure',
    description: 'The lesson generation failed after all retries.',
    type: NotificationType.ALERT,
  },
  chat: {
    title: 'Chat Message Generation Failure',
    description:
      'The system could not generate your chat message after multiple attempts.',
    type: NotificationType.ALERT,
  },
};
