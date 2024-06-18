import { z } from 'zod';
export const messageSchema = z
  .object({
    message: z.string().optional(),
    refId: z.string().min(1, { message: 'Ref Id is required' }),
    attachmentId: z.string().optional(),
    audioDuration: z.number().optional(),
  })
  .refine((data) => data.message || data.attachmentId, {
    message: 'Either message or attachmentId must be provided',
  })
  .refine((data) => !(data.attachmentId && data.audioDuration === undefined), {
    message: 'audioDuration is required when audioUrl is present',
  });
