export type LearnPayload = {
  id: string;
  languageId: string;
  userId: string;
  reason: string;
  knowledge: string;
  type: string;
  createdAt: string;
  updatedAt: string;
  language: {
    flagUrl: string;
    name: string;
    id: string;
  };
  modules: any[];
};
