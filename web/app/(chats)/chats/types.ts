export interface Chat {
  name: string;
  updatedAt: string;
  voice: {
    name: string;
    id: string;
    language?: string;
  };
  initialPrompt?: string;
  id: string;
}
