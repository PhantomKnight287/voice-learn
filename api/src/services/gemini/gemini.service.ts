import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { generateObject, generateText, streamObject, streamText } from 'ai';
import { google } from '@ai-sdk/google';
import { openai } from '@ai-sdk/openai';
@Injectable()
export class GeminiService {
  constructor(protected readonly configService: ConfigService) {}

  async streamText(
    props: Omit<Parameters<Awaited<typeof streamText>>[0], 'model'>,
  ) {
    return await streamText({
      ...props,
      model: google('models/gemini-1.5-pro-latest'),
    });
  }

  async generateText(
    props: Omit<Parameters<Awaited<typeof generateText>>[0], 'model'>,
  ) {
    return await generateText({
      ...props,
      model: google('models/gemini-1.5-pro-latest'),
    });
  }

  async generateObject(
    props: Omit<Parameters<Awaited<typeof generateObject>>[0], 'model'>,
  ) {
    return await generateObject({
      ...props,
      model: google('models/gemini-1.5-pro-latest'),
    });
  }

  async streamObject(
    props: Omit<Parameters<Awaited<typeof streamObject>>[0], 'model'>,
  ) {
    return await streamObject({
      ...props,
      model: google('models/gemini-1.5-pro-latest'),
    });
  }
}
