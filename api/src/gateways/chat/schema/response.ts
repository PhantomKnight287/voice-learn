import { z } from 'zod';

export const llmTextResponse = z.object({
  response: z.string(),
});
