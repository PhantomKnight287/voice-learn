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
import * as OneSignal from '@onesignal/node-onesignal';

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
  DEV: z.string().optional(),
  R2_PUBLIC_BUCKET_NAME: z.string(),
  R2_PUBLIC_BUCKET_URL: z.string(),
  ONESIGNAL_APP_ID: z.string(),
  ONESIGNAL_REST_API_KEY: z.string(),
  EMAILTHING_TOKEN: z.string(),
  RESET_PASSWORD_SECRET: z.string(),
  HOST:z.string(),
  ADMIN_USER_ID:z.string(),
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

export const ELEVENLABS_API_URL = 'https://api.elevenlabs.io/v1';

export const PRODUCTS = {
  emeralds_100: 100,
  emeralds_200: 200,
  emeralds_500: 500,
  emeralds_1000: 1000,
};

export const onesignal = new OneSignal.DefaultApi(
  OneSignal.createConfiguration({
    authMethods: {
      rest_api_key: {
        tokenProvider: {
          getToken() {
            return process.env.ONESIGNAL_REST_API_KEY;
          },
        },
      },
    },
  }),
);

export const testSentences = {
  Afrikaans: 'Hallo, dit is die spoed van die stem',
  Arabic: 'مرحباً، هذه هي سرعة الصوت',
  Armenian: 'Բարև, սա ձայնի արագությունն է',
  Azerbaijani: 'Salam, bu səsin sürətidir',
  Belarusian: 'Прывітанне, гэта хуткасць голасу',
  Bosnian: 'Zdravo, ovo je brzina glasa',
  Bulgarian: 'Здравейте, това е скоростта на гласа',
  Catalan: 'Hola, aquesta és la velocitat de la veu',
  Chinese: '你好，这是声音的速度',
  Croatian: 'Pozdrav, ovo je brzina glasa',
  Czech: 'Ahoj, toto je rychlost hlasu',
  Danish: 'Hej, dette er hastigheden af stemmen',
  Dutch: 'Hallo, dit is de snelheid van de stem',
  English: 'Hello, this is the speed of the voice',
  Estonian: 'Tere, see on hääle kiirus',
  Finnish: 'Hei, tämä on äänen nopeus',
  Galician: 'Ola, esta é a velocidade da voz',
  German: 'Hallo, dies ist die Geschwindigkeit der Stimme',
  Greek: 'Γεια σας, αυτή είναι η ταχύτητα της φωνής',
  Hebrew: 'שלום, זו מהירות הקול',
  Hindi: 'नमस्ते, यह आवाज़ की गति है',
  Hungarian: 'Helló, ez a hang sebessége',
  Icelandic: 'Halló, þetta er hraði raddarinnar',
  Indonesian: 'Halo, ini adalah kecepatan suara',
  Italian: 'Ciao, questa è la velocità della voce',
  Japanese: 'こんにちは、これは声の速度です',
  Korean: '안녕하세요, 이것은 목소리의 속도입니다',
  Latvian: 'Sveiki, šis ir balss ātrums',
  Norwegian: 'Hei, dette er hastigheten på stemmen',
  Polish: 'Cześć, to jest prędkość głosu',
  Portuguese: 'Olá, esta é a velocidade da voz',
  Romanian: 'Salut, aceasta este viteza vocii',
  Russian: 'Здравствуйте, это скорость голоса',
  Serbian: 'Здраво, ово је брзина гласа',
  Spanish: 'Hola, esta es la velocidad de la voz',
  Swedish: 'Hej, detta är hastigheten på rösten',
  Thai: 'สวัสดี นี่คือความเร็วของเสียง',
  Turkish: 'Merhaba, bu sesin hızıdır',
  Ukrainian: 'Привіт, це швидкість голосу',
  Vietnamese: 'Xin chào, đây là tốc độ của giọng nói',
  French: "Bonjour, c'est la vitesse de la voix",
};
