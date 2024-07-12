export interface Voice {
  id: string;
  name: string;
  accent: string;
  gender: string;
  description: string;
  previewUrl: string;
  language?: string;
  createdAt: string;
  updatedAt: string;
  _count: {
    chats: number;
  };
}

export interface CreateChatResponse {
  id: string;
}
