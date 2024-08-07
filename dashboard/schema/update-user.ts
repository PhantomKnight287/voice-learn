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

export const removeAvatarSchema = z.object({
  updateReasonTitle: z.string(),
  updateReasonDescription: z.string(),
});

export enum NotificationType {
  ALERT = "ALERT",
  WARNING = "WARNING",
  INFO = "INFO",
  SUCCESS = "SUCCESS",
}

export const sendNotificationSchema = z.object({
  title: z.string(),
  description: z.string(),
  type: z.nativeEnum(NotificationType),
});
