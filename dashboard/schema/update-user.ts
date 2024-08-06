import { z } from "zod";
export const updateUserSchema = z.object({
  name: z.string().optional(),
  emeralds: z.number().optional(),
  xp: z.number().optional(),
  voiceMessages: z.number().optional(),
  lives: z.number().optional(),
  updateReasonTitle: z.string(),
  updateReasonDescription: z.string(),
});
