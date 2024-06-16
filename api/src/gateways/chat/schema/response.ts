import { z } from 'zod';

export const llmTextResponse = z.array(
  z.object({
    word: z.string(),
    translation: z.string(),
  }),
);
