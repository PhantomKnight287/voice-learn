import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { generateObject, generateText, streamObject, streamText } from 'ai';
import { google } from '@ai-sdk/google';
import { z } from 'zod';
@Injectable()
export class GeminiService {
  constructor(protected readonly configService: ConfigService) {}

  async streamText(
    props: Omit<Parameters<Awaited<typeof streamText>>[0], 'model'> & {
      model?: Pick<Parameters<Awaited<typeof streamText>>[0], 'model'>['model'];
    },
  ) {
    return await streamText({
      ...props,
      model:
        props.model ??
        google('models/gemini-1.5-flash-latest', {
          safetySettings: [
            {
              category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_HARASSMENT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_HATE_SPEECH',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
          ],
        }),
      maxRetries: 0,
    });
  }

  async generateText(
    props: Omit<Parameters<Awaited<typeof generateText>>[0], 'model'> & {
      model?: Pick<Parameters<Awaited<typeof streamText>>[0], 'model'>['model'];
    },
  ) {
    return await generateText({
      ...props,
      model:
        props.model ??
        google('models/gemini-1.5-flash-latest', {
          safetySettings: [
            {
              category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_HARASSMENT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_HATE_SPEECH',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
          ],
        }),
      maxRetries: 0,
    });
  }

  async generateObject(
    props: Omit<Parameters<Awaited<typeof generateObject>>[0], 'model'> & {
      model?: Pick<Parameters<Awaited<typeof streamText>>[0], 'model'>['model'];
    },
  ) {
    return await generateObject<z.infer<typeof props.schema>>({
      ...props,
      model:
        props.model ??
        google('models/gemini-1.5-flash-latest', {
          safetySettings: [
            {
              category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_HARASSMENT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_HATE_SPEECH',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
          ],
        }),
      maxRetries: 0,
    });
  }

  async streamObject(
    props: Omit<Parameters<Awaited<typeof streamObject>>[0], 'model'> & {
      model?: Pick<Parameters<Awaited<typeof streamText>>[0], 'model'>['model'];
    },
  ) {
    return await streamObject({
      ...props,
      model:
        props.model ??
        google('models/gemini-1.5-flash-latest', {
          safetySettings: [
            {
              category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_HARASSMENT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_HATE_SPEECH',
              threshold: 'BLOCK_ONLY_HIGH',
            },
            {
              category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              threshold: 'BLOCK_ONLY_HIGH',
            },
          ],
        }),
      maxRetries: 0,
    });
  }
}
