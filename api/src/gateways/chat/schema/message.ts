import { z } from 'zod';
export const messageSchema = z.object({
  message: z.string().min(1, { message: 'Please enter a text message' }),
  refId: z.string().min(1, { message: 'Ref Id is required' }),
});
