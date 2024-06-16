/* eslint-disable @typescript-eslint/no-empty-interface */

/* eslint-disable @typescript-eslint/no-namespace */
import { Subject } from 'rxjs';
import _pusher from 'pusher';
import 'dotenv/config';
import { z } from 'zod';
export const ONBOARDING_QUEUE = 'onboarding';

export const PATH_GENERATION_SUBJECT = new Subject<string>();

export const envSchema = z.object({
  DATABASE_URL: z.string(),
  JWT_SECRET: z.string(),
  R2_BUCKET_NAME: z.string(),
  R2_KEY_ID: z.string(),
  CF_ACCOUNT_ID: z.string(),
  GOOGLE_GENERATIVE_AI_API_KEY: z.string(),
  REDIS_HOST: z.string(),
  REDIS_PASSWORD: z.string(),
  OPENAI_API_KEY: z.string(),
  PUSHER_APP_ID: z.string(),
  PUSHER_APP_KEY: z.string(),
  PUSHER_SECRET: z.string(),
  PUSHER_CLUSTER: z.string(),
  LOGSTRAP_PATH: z.string().optional(),
  LOGSTRAP_KEY: z.string().optional(),
  ELEVENLABS_API_KEY:z.string(),
});

const safeParseResult = envSchema.safeParse(process.env);
if (safeParseResult.success === false) {
  throw new Error(
    `${safeParseResult.error.errors[0].path} is required in .env`,
  );
}

export const pusher = new _pusher({
  appId: process.env.PUSHER_APP_ID,
  cluster: process.env.PUSHER_CLUSTER,
  key: process.env.PUSHER_APP_KEY,
  secret: process.env.PUSHER_SECRET,
});

declare global {
  namespace NodeJS {
    interface ProcessEnv extends z.infer<typeof envSchema> {}
  }
}


export const errorSubject$ = new Subject<any>();