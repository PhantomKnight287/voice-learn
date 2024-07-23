import { Controller, Logger } from '@nestjs/common';
import { EventsService } from './events.service';
import { OnEvent } from '@nestjs/event-emitter';
import { prisma } from 'src/db';
import { GeminiService } from 'src/services/gemini/gemini.service';
import {
  learning_path_schema,
  lessons_schema,
  modules_schema,
  questions_schema,
} from 'src/schemas';
import { z } from 'zod';
import { createId } from '@paralleldrive/cuid2';
import { queue } from 'src/services/queue/queue.service';
import { failureNotifications, QueueItemObject } from 'src/types/queue';
import {
  elevenLabs,
  messageSubject,
  openai,
  pusher,
  userUpdateSubject,
} from 'src/constants';
import { llmTextResponse } from 'src/gateways/chat/schema/response';
import { ConfigService } from '@nestjs/config';
import { S3Service } from 'src/services/s3/s3.service';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import { parseBuffer } from 'music-metadata';
import { openai as aiSdkOpenAI } from '@ai-sdk/openai';
import { NotificationsService } from '../notifications/notifications.service';
@Controller('events')
export class EventsController {
  private readonly logger = new Logger(EventsController.name);
  constructor(
    private readonly eventsService: EventsService,
    private readonly geminiService: GeminiService,
    private readonly s3Service: S3Service,
    private readonly configService: ConfigService,
    private readonly notificationService: NotificationsService,
  ) {}

  @OnEvent('queue.handle')
  async createLearningPath(body: QueueItemObject) {
    try {
      console.log(
        `Got event with id ${body.id} at ${new Date().toLocaleString()}`,
      );
      if (body.type === 'question') {
        const lesson = await prisma.lesson.findFirst({
          where: { id: body.id },
          include: {
            module: {
              include: {
                learningPath: {
                  include: { language: true, user: { select: { tier: true } } },
                },
              },
            },
          },
        });
        if (!lesson) return;
        const data = await this.geminiService.generateObject({
          schema: questions_schema,
          messages: [
            {
              role: 'system',
              content: `You are a language learning expert who can generate questions for the given language based on the given lesson name and description. You have to generate EXACTLY ${lesson.questionsCount} questions.

Every question will be an object with these 4 values:

instruction: The instruction to student on how to solve the question (for example: "Translate this sentence to English", "Choose the correct word.")
type: Type of question (it must be one from 'sentence', 'select_one' or 'fill_in_the_blank')
options: It should contain options for the questions if the type is 'select_one', otherwise it must be empty if type is 'sentence'. Ensure the options are unique to the question and do not repeat.
correctAnswer: The correct answer to the question. This can include special characters. This must never be empty and should be one from "options" if type is "select_one" or the answer if type is "sentence".
questions: It will be an array of objects where each object contains 'word' and its translation as 'translation' field. (It must be a single word only)
Here is how your response should look like (note that it's an example response and the questions and question count should be equal to the given question count):
               [
  {
    "instruction": "Choose correct word.",
    "type": "select_one",
    "options": ["Good Morning", "Good Evening", "Good Bye"],
    "correctAnswer": "Good Morning",
    "questions": [
      {
        "word": "Guten",
        "translation": "Good"
      },
      {
        "word": "Morgen",
        "translation": "Morning"
      }
    ]
  },
  {
    "instruction": "Translate the given word.",
    "type": "select_one",
    "options": ["zwei", "eins", "drei"],
    "correctAnswer": "drei",
    "questions": [
      {
        "word": "3",
        "translation": "drei"
      }
    ]
  },
  {
    "instruction": "Choose the correct word.",
    "type": "select_one",
    "options": ["Katze", "Hund", "Fisch"],
    "correctAnswer": "Hund",
    "questions": [
      {
        "word": "Dog",
        "translation": "Hund"
      }
    ]
  },
  {
    "instruction": "Choose the correct word",
    "type": "select_one",
    "options": ["Name", "heißt", "Wo"],
    "correctAnswer": "heißt",
    "questions": [
      {
        "word": "Name",
        "translation": "heißt"
      }
    ]
  },
  {
    "instruction": "Translate the given sentence",
    "type": "sentence",
    "questions": [
      {
        "word": "I",
        "translation": "Ich"
      },
      {
        "word": "am going",
        "translation": "gehe"
      },
      {
        "word": "to the",
        "translation": "zum"
      },
      {
        "word": "store",
        "translation": "Laden"
      }
    ]
  },
  {
    "instruction":"Enter correct word",
    "type":"fill_in_the_blank",
    "questions": [
      {
        "word": "I",
        "translation": "Ich"
      },
      {
        "word": "am going",
        "translation": "gehe"
      },
      {
        "word": "to the",
        "translation": "zum"
      },
      {
        "word": "<empty>",
        "translation": "<empty>"
      }
    ],
    "options": ["Laden", "Morgen", "Tag"],
    "correctAnswer": "Laden",
  }
]


	**Constraints**:

- Do not generate any escape characters.
- The instructions must not include the question.
- The questions should be of all types and not just of one type.
- The "questions" array must never be empty and should always contain meaningful content.
- Do not put the answer of the question in the "questions" array.
- Please do not use any type of placeholders like [Enter your name here].
- Note: Do not respond with anything except the array of objects. The response should be a valid JSON array, otherwise the code will break.
- For 'fill_in_the_blank', the blank word should be "<empty>"
`,
            },

            {
              role: 'user',
              content: `
Generate ${lesson.questionsCount} questions for ${lesson.module.learningPath.language.name} language learning program.

Here is the information about lesson:

Lesson name: ${lesson.name}
Lesson description: ${lesson.description}

${lesson.explanation ? `Lesson Explanation: ${lesson.explanation}` : ''}

Please do not generate unrelated questions. 
`,
            },
          ],
        });
        const startTime = new Date().getTime();

        await prisma.$transaction(async (tx) => {
          let idx = 0;
          for (const question of data.object as z.infer<
            typeof questions_schema
          >) {
            await tx.question.create({
              data: {
                correctAnswer: question.correctAnswer,
                instruction: question.instruction,
                id: `question_${createId()}`,
                question: question.questions,
                options: question.options,
                type: question.type,
                createdAt: new Date(startTime + 1000 * idx),
                lessons: {
                  connect: {
                    id: lesson.id,
                  },
                },
              },
            });
            idx += 1;
          }
          await prisma.lesson.update({
            where: { id: lesson.id },
            data: { questionsStatus: 'generated' },
          });
        });
        await pusher.trigger(
          'modules',
          'module_generated',
          lesson.module.learningPath.userId,
        );
      } else if (body.type === 'modules') {
        const request = await prisma.generationRequest.findFirst({
          where: { id: body.id },
        });
        if (!request) return;
        const learningPath = await prisma.learningPath.findFirst({
          where: {
            userId: request.userId,
          },
          select: {
            id: true,
            language: {
              select: {
                name: true,
              },
            },
            modules: {
              select: {
                name: true,
                description: true,
              },
            },
            reason: true,
            knowledge: true,
            user: {
              select: {
                tier: true,
              },
            },
          },
        });
        const messages: Parameters<
          Awaited<typeof this.geminiService.generateObject>
        >['0']['messages'] = [
          {
            role: 'system',
            content: `
            **Objective**: Generate a JSON structure for a ${learningPath.language.name} language learning program.

**Context**: The user wants to learn ${learningPath.language.name} for ${learningPath.reason} and their current knowledge level is ${learningPath.knowledge}. The user has already studied the following modules: ${learningPath.modules}

**Requirements**:

**Modules**: The program should consist of 10 modules.
**Lessons**: Each module should contain at least 8 lessons.


**Lesson Details**:
**Name**: Provide a meaningful name for each lesson (e.g., "Basic Greetings").
**Description**: Offer a useful description without special characters or generic phrases like "Module 1". The description should not start with "This Module covers" or "This lesson covers".
**Explanation**: Provide an introduction explaining the necessity and variations of what is being learned. Include a few example words that will be taught in the lesson. The explanation should be detailed and formatted in markdown with proper list formatting, headings and tables if needed (e.g., "Understanding basic greetings is essential for starting conversations. You'll learn common phrases like 'Hola' and 'Buenos días', which are used in everyday interactions.").
**questionsCount**: Indicate the number of questions that each lesson must have (e.g., If you are teaching Greetings then it should count them as Good Morning, Afternoon, Evening, Night, Hello etc and their formal versions too. If you are teaching numbers from 1-10 then it should be 10 questions).

**Constraints**:

- Avoid using special characters in names and descriptions.
- Ensure descriptions and explanations are practical and engaging.
- Do not use words like "pronunciation".
- Do not generate already studied modules.

**Output Requirements**:

Only generate an array of modules.
No escape characters in the JSON structure

**Style/Tone**: The content should be educational and accessible, suitable for learners at different levels.
            `,
          },
        ];
        if (request.prompt) {
          messages.push({
            role: 'user',
            content: request.prompt,
          });
        }
        const data = await this.geminiService.generateObject({
          schema: modules_schema,
          messages,
        });
        const response = data.object as z.infer<typeof modules_schema>;
        await prisma.$transaction(async (tx) => {
          await tx.generationRequest.update({
            where: { id: request.id },
            data: { completed: true },
          });

          for (const module of response) {
            const startTime = new Date().getTime();
            await tx.module.create({
              data: {
                id: `module_${createId()}`,
                description: module.description,
                name: module.name,
                learningPathId: learningPath.id,
                lessons: {
                  createMany: {
                    data: module.lessons.map((lesson, index) => ({
                      name: lesson.name,
                      id: `lesson_${createId()}`,
                      completed: false,
                      description: lesson.description,
                      questionsCount: lesson.questionsCount,
                      createdAt: new Date(startTime + 1000 * index),
                      explanation: lesson.explanation,
                    })),
                  },
                },
              },
            });
          }
        });
        await pusher.trigger('modules', 'module_generated', request.userId);
      } else if (body.type === 'lessons') {
        const request = await prisma.generationRequest.findFirst({
          where: { id: body.id },
        });
        if (!request) return;
        const module = await prisma.module.findFirst({
          where: {
            id: request.moduleId,
          },
          include: {
            learningPath: {
              select: {
                language: {
                  select: {
                    name: true,
                  },
                },
                reason: true,
                knowledge: true,
                user: { select: { tier: true } },
              },
            },
            lessons: {
              select: {
                name: true,
                description: true,
                questionsCount: true,
                explanation: true,
              },
              where: {
                name: { not: 'Mistake Correction' },
              },
            },
          },
        });
        const messages: Parameters<
          Awaited<typeof this.geminiService.generateObject>
        >['0']['messages'] = [
          {
            role: 'system',
            content: `
**Objective**: Generate a JSON structure for lessons belonging to a ${module.learningPath.language.name} language learning program.

**Context**: The user wants to learn ${module.learningPath.language.name} for ${module.learningPath.reason} and has a knowledge level of ${module.learningPath.knowledge}. The user has already studied the following lessons: ${module.lessons.join('\n, ')}.

**Requirements**:

**Lessons**: Generate 8 lessons.


**Lesson Details**:

**Name**: Provide a meaningful and descriptive name for each lesson.
**Description**: Offer a useful description without special characters or generic phrases like "Module 1". The description should not start with "This Module covers" or "This lesson covers".
**Explanation**: Provide an introduction explaining the necessity and variations of what is being learned. Include a few example words that will be taught in the lesson. The explanation should be detailed and formatted in markdown (e.g., "Understanding basic greetings is essential for starting conversations. You'll learn common phrases like 'Hola' and 'Buenos días', which are used in everyday interactions.").
**questionsCount**: Indicate the number of questions that each lesson must have.


Constraints:

- Ensure descriptions and explanations are practical and engaging.
- Do not use words like "pronunciation".
- Do not generate already studied lessons. This includes same lesson with different names.
- The lesson difficulty should go from least to most and it should increase slowly.

**Output Requirements**:

- Only generate an array of lessons.
- No escape characters in the JSON structure.
- Style/Tone: The content should be educational and accessible, suitable for learners at different levels.

`,
          },
        ];
        if (request.prompt) {
          messages.push({
            role: 'user',
            content: request.prompt,
          });
        }
        const data = await this.geminiService.generateObject({
          schema: lessons_schema,
          messages,
        });
        const response = data.object as z.infer<typeof lessons_schema>;
        await prisma.$transaction(async (tx) => {
          await tx.generationRequest.update({
            where: { id: request.id },
            data: { completed: true },
          });
          const startTime = new Date().getTime();

          await tx.lesson.createMany({
            data: response.map((response, index) => ({
              id: `lesson_${createId()}`,
              description: response.description,
              questionsCount: response.questionsCount,
              name: response.name,
              createdAt: new Date(startTime + 1000 * index),
              moduleId: module.id,
              explanation: response.explanation,
            })),
          });
        });
        await pusher.trigger('modules', 'module_generated', request.userId);
      } else if (body.type === 'chat') {
        const chat = await prisma.chat.findFirst({
          where: {
            id: body.id,
          },
          include: {
            language: true,
            voice: true,
            messages: {
              take: 100,
              orderBy: [
                {
                  createdAt: 'desc',
                },
              ],
            },
            user: { select: { tier: true } },
          },
        });

        const userMessage = await prisma.message.findFirst({
          where: { id: body.messageId },
          include: {
            attachment: { select: { id: true } },
          },
        });
        const text = userMessage.content;

        const res = await this.geminiService.generateObject({
          schema: llmTextResponse,
          messages: [
            {
              role: 'system',
              content: `Your name is ${chat.voice.name} ${chat.initialPrompt ? `${chat.initialPrompt}. ` : ''}${
                chat.language.name.toLowerCase() === 'multiple'
                  ? 'Reply in the language the question is asked.'
                  : `Reply in ${chat.language.name}.`
              } Ensure your responses are sensible and relevant to the user's message. Avoid generating unrelated content and refrain from providing code assistance.`,
            },
            {
              role: 'system',
              content: `Your response must be an object containing "response", which is an array of objects where 'word' will be the actual word in ${chat.language.name} and 'translation' will be the translation in English. Example: [{"word":"Guten","translation":"Good"},{"word":"morgen","translation":"morning"}]
  
  Generate responses that are relevant and meaningful to the user's input. Avoid generating nonsensical or out-of-context content.`,
            },
            //@ts-expect-error
            ...(chat.user.tier === 'free'
              ? chat.messages.slice(0, 20)
              : chat.messages
            )
              .reverse()
              .map((message) => ({
                role: message.author === 'Bot' ? 'assistant' : 'user',
                content: `${message.content
                  .map((message: any) => ({
                    word: message.word,
                    translation: message.translation || '',
                  }))
                  .join('\n')}`,
              })),
            {
              content: text.map((e) => (e as { word: string }).word).join(' '),
              //@ts-expect-error
              role: 'user',
            },
          ],
        });
        let audio: ArrayBuffer;
        let llmAudio: string;
        let duration: number = 0;
        if (chat.voice.provider === 'OpenAI' && userMessage.attachmentId) {
          const voice = await openai.audio.speech.create({
            model: 'tts-1',
            input: (
              res.object as unknown as z.infer<typeof llmTextResponse>
            ).response
              .map((word) => word.word)
              .join(' '),
            //setting any as the provider is OpenAI so voices are already verified
            voice: chat.voice.name.toLowerCase() as any,
            speed: 1,
            response_format: 'mp3',
          });
          audio = await voice.arrayBuffer();
        } else if (
          userMessage.attachmentId &&
          chat.voice.provider == 'XILabs'
        ) {
          const audioStream = await elevenLabs.generate({
            voice: chat.voice.name,
            text: (
              res.object as unknown as z.infer<typeof llmTextResponse>
            ).response
              .map((word) => word.word)
              .join(' '),
            model_id: 'eleven_multilingual_v2',
            stream: true,
            enable_logging: true,
          });
          const chunks: Buffer[] = [];
          for await (const chunk of audioStream) {
            chunks.push(chunk);
          }
          audio = Buffer.concat(chunks).buffer;
        }
        if (audio) {
          const key = `${userMessage.id}____${chat.id}____${chat.voice.name}____${chat.voice.provider}____${chat.language.name}____${randomUUID()}.mp3`;
          await this.s3Service.putObject({
            Bucket: process.env.R2_BUCKET_NAME,
            Key: key,
            Body: new Uint8Array(audio),
            ContentType: `audio/mpeg`,
          });
          const url = await getSignedUrl(
            this.s3Service,
            new GetObjectCommand({
              Bucket: this.configService.getOrThrow('R2_BUCKET_NAME'),
              Key: key,
            }),
            {
              expiresIn: 60 * 60 * 24 * 7, // 1 week
            },
          );
          const upload = await prisma.upload.create({
            data: {
              id: `upload_bot_${createId()}`,
              key: key,
              url: url,
              expiresAt: new Date(Date.now() + 24 * 7 * 60 * 60 * 1000),
              userId: chat.userId,
            },
          });
          llmAudio = upload.id;
          const { format } = await parseBuffer(new Uint8Array(audio));
          duration = format.duration;
          const user = await prisma.user.update({
            where: {
              id: chat.userId,
            },
            data: {
              emeralds: {
                decrement: 1,
              },
            },
          });
          userUpdateSubject.next({ ...user, chatId: chat.id });
        }
        const llmMessage = await prisma.message.create({
          data: {
            id: `message_${createId()}`,
            content: (res.object as z.infer<typeof llmTextResponse>).response,
            author: 'Bot',
            chatId: body.id,
            attachmentId: llmAudio,
            audioDuration: duration,
          },
          include: {
            attachment: { select: { id: true } },
          },
        });
        messageSubject.next(llmMessage);
      } else {
        const path = await prisma.learningPath.findFirst({
          include: { language: true, user: { select: { tier: true } } },
          where: { id: String(body.id) },
        });
        if (!path) return;

        const data = await this.geminiService.generateObject({
          schema: learning_path_schema,
          model: path.user.tier === 'free' ? undefined : aiSdkOpenAI('gpt-4o'),
          messages: [
            {
              role: 'system',
              content: `You are a ${path.language.name} speaker with highest proficiency in ${path.language.name}. You have to generate learning path for people with little to no knowledge of ${path.language.name}. You must keep everything to the point and not generate anything out of the context.`,
            },
            {
              role: 'user',
              content: `
**Objective**: Generate a JSON structure for a ${path.language.name} language learning program.

**Context**: The program is designed to help users learn ${path.language.name} through a structured curriculum.

**Requirements**:

**Modules**: The program should consist of 10 modules. The module is like a category just like a chapter in a book having a name and a short description.
**Lessons**: Each module should contain at least 8 lessons.

**Lesson Details**:

**Name**: Provide a meaningful name for each lesson (e.g., "Basic Greetings").
**Description**: Offer a useful description without special characters or generic phrases like "Module 1". The description should not start with "This Module covers" or "This lesson covers".
**Explanation**: Instead of directly covering the topics, provide an introduction explaining the necessity and variations of what is being learned. Include a few example words that will be taught in the lesson. The explanation should be detailed and divide it into paragraphs for better attention grabbing and formatted in markdown using proper headings and list items and table if needed (e.g., "Understanding basic greetings is essential for starting conversations. You'll learn common phrases like 'Hola' and 'Buenos días', which are used in everyday interactions.").
**questionsCount**: Indicate the number of questions that each lesson must have (e.g., If you are teaching Greetings then it should count them as Good Morning, Afternoon, Evening, Night, Hello etc and their formal versions too. If you are teaching numbers from 1-10 then it should be 10 questions).

**Constraints**:

- Avoid using special characters in names and descriptions.
- Ensure descriptions and explanations are practical and engaging.
- Do not use words like "pronunciation".
- The name and description must be in English no matter what. 
- There should be no unrelated content in a module. For example, if a module is called "Basic Greetings" then it should it have lessons related to greetings and addressing people and nothing else.
- The Modules should go from very basic to advanced bit by bit.

**Style/Tone**: The content should be educational and accessible, suitable for learners at ${path.knowledge}. Try to start with as basic items as possible based on user's level.`,
            },

            {
              role: 'user',
              content: `I want to learn ${path.language.name} and I am ${path.knowledge}. I want to learn ${path.language.name}.`,
            },
          ],
        });
        const object: z.infer<typeof learning_path_schema> = data.object;

        for (const path of object.paths) {
          await prisma.$transaction(async (tx) => {
            await tx.learningPath.update({
              where: { id: body.id },
              data: {
                modules: {
                  create: path.modules.map((module) => ({
                    name: module.name,
                    id: `module_${createId()}`,
                    description: module.description,
                  })),
                },
              },
            });
            for (const pathModule of path.modules) {
              const module = await tx.module.findFirst({
                where: { name: pathModule.name, learningPathId: body.id },
              });
              if (!module) continue;
              const startTime = new Date().getTime();
              await tx.module.update({
                where: { id: module.id },
                data: {
                  lessons: {
                    create: pathModule.lessons.map((lesson, idx) => ({
                      name: lesson.name,
                      id: `lesson_${createId()}`,
                      questionsCount: lesson.questionsCount,
                      createdAt: new Date(startTime + 1000 * idx),
                      explanation: lesson.explanation,
                      description: lesson.description,
                    })),
                  },
                },
              });
              if (
                pathModule.name === path.modules[path.modules.length - 1].name
              ) {
                await tx.learningPath.update({
                  data: { type: 'generated' },
                  where: {
                    id: body.id,
                  },
                });
              }
            }
          });
        }
      }

      console.log('generated ' + body.type);
    } catch (error) {
      if (body.retries >= 5 && body.type !== 'learning_path') {
        await this.notificationService.createNotification(
          body.userId,
          failureNotifications[body.type],
        );
        return;
      }
      await queue.addToQueueWithPriority({
        ...body,
        retries: (body.retries || 0) + 1,
      });
    }
  }
}
