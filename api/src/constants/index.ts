/* eslint-disable @typescript-eslint/no-empty-interface */

/* eslint-disable @typescript-eslint/no-namespace */
import { Subject } from 'rxjs';
import _pusher from 'pusher';
import 'dotenv/config';
import { z } from 'zod';
import { Message, User } from '@prisma/client';
import OpenAI from 'openai';
export const ONBOARDING_QUEUE = 'onboarding';
import { ElevenLabsClient } from 'elevenlabs';
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
  ELEVENLABS_API_KEY: z.string(),
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

export const locales = {
  Afrikaans: 'af-ZA',
  Arabic: 'ar-SA',
  Armenian: 'hy-AM',
  Azerbaijani: 'az-AZ',
  Belarusian: 'be-BY',
  Bosnian: 'bs-BA',
  Bulgarian: 'bg-BG',
  Catalan: 'ca-ES',
  Chinese: 'zh-CN',
  Croatian: 'hr-HR',
  Czech: 'cs-CZ',
  Danish: 'da-DK',
  Dutch: 'nl-NL',
  English: 'en-US',
  Estonian: 'et-EE',
  Finnish: 'fi-FI',
  Galician: 'gl-ES',
  German: 'de-DE',
  Greek: 'el-GR',
  Hebrew: 'he-IL',
  Hindi: 'hi-IN',
  Hungarian: 'hu-HU',
  Icelandic: 'is-IS',
  Indonesian: 'id-ID',
  Italian: 'it-IT',
  Japanese: 'ja-JP',
  Korean: 'ko-KR',
  Latvian: 'lv-LV',
  Norwegian: 'no-NO',
  Polish: 'pl-PL',
  Portuguese: 'pt-PT',
  Romanian: 'ro-RO',
  Russian: 'ru-RU',
  Serbian: 'sr-RS',
  Spanish: 'es-ES',
  Swedish: 'sv-SE',
  Thai: 'th-TH',
  Turkish: 'tr-TR',
  Ukrainian: 'uk-UA',
  Vietnamese: 'vi-VN',
  French: 'fr-FR',
};

export const messageSubject = new Subject<Message>();

export const queuePositionSubject = new Subject<number>();

export const userUpdateSubject = new Subject<User & { chatId: string }>();

export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export const elevenLabs = new ElevenLabsClient({
  apiKey: process.env.ELEVENLABS_API_KEY,
});
