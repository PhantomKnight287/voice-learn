import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';
import morgan from 'morgan';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import './constants';
import { ELEVENLABS_API_URL, errorSubject$, onesignal } from './constants';

import { prisma } from './db';
import { Voice } from './types/voice';
import { createId } from '@paralleldrive/cuid2';

const OPENAI_VOICES = ['Alloy', 'Echo', 'Fable', 'Onyx', 'Nova', 'Shimmer'];

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(morgan('dev'), helmet());

  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
    }),
  );
  if (process.env.LOGSTRAP_KEY && process.env.LOGSTRAP_PATH)
    errorSubject$.subscribe((payload) => {
      fetch(process.env.LOGSTRAP_PATH, {
        method: 'POST',
        body: JSON.stringify(payload),
        headers: {
          'X-API-KEY': process.env.LOGSTRAP_KEY,
          'content-type': 'application/json',
        },
      }).catch(() => {});
    });
  await app.listen(5000);
  await fetchVoices();
  await loadOpenAiVoices();
}
bootstrap();

async function fetchVoices() {
  const req = await fetch(`${ELEVENLABS_API_URL}/voices?page_size=100`, {
    headers: {
      'xi-api-key': process.env.ELEVENLABS_API_KEY,
    },
  });
  const body = await req.json();
  if (!req.ok) {
    console.error(body);
    return;
  }
  const voices = body.voices as Voice[];
  for (const voice of voices) {
    await prisma.voice.upsert({
      where: {
        id: voice.voice_id,
      },
      update: {
        description: voice.description,
        name: voice.name,
        previewUrl: voice.preview_url,
        accent: voice.labels.accent,
        gender: voice?.labels?.gender,
        provider: 'XILabs',
        tiers: ['premium', 'epic'],
      },
      create: {
        description: voice.description,
        id: voice.voice_id,
        name: voice.name,
        previewUrl: voice.preview_url,
        accent: voice.labels.accent,
        gender: voice?.labels?.gender,
        provider: 'XILabs',
        tiers: ['premium', 'epic'],
      },
    });
  }
}

async function loadOpenAiVoices() {
  for (const voice of OPENAI_VOICES) {
    const voiceInDB = await prisma.voice.findFirst({
      where: { name: voice, provider: 'OpenAI' },
    });
    if (voiceInDB) {
      await prisma.voice.update({
        where: {
          id: voiceInDB.id,
        },
        data: {
          name: voice,
          previewUrl: `https://cdn.openai.com/API/docs/audio/${voice.toLowerCase()}.wav`,
          tiers: ['free'],
        },
      });
    } else {
      await prisma.voice.create({
        data: {
          name: voice,
          id: `voice_${createId()}`,
          previewUrl: `https://cdn.openai.com/API/docs/audio/${voice.toLowerCase()}.wav`,
          tiers: ['free'],
          provider: 'OpenAI',
        },
      });
    }
  }
}
