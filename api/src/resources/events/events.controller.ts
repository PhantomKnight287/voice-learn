import { Controller } from '@nestjs/common';
import { EventsService } from './events.service';
import { OnEvent } from '@nestjs/event-emitter';
import { CreatePathEvent } from 'src/events';
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
import { QueueItemObject } from 'src/types/queue';
import { pusher } from 'src/constants';

@Controller('events')
export class EventsController {
  constructor(
    private readonly eventsService: EventsService,
    private readonly geminiService: GeminiService,
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
                learningPath: { include: { language: true } },
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
              content: `Generate a JSON ARRAY structure for questions of ${lesson.module.learningPath.language.name} language learning program and for lesson with name ${lesson.name} and description ${lesson.description}. There must be ${lesson.questionsCount} questions. The "instruction" should be the instruction to student on how to solve the question(for example: Translate this sentence to English.), type must either be 'sentence' or 'select_one'. The "options" array must never be empty. The "correctAnswer" should be the correct answer of the question and should not include any special characters including "...". The "question" must be an array of objects of words in question. Do not return excess whitespace, escape characters and punctuation in your response.
              
              Below are examples of questions:

                [
              {
                "instruction":"What is the meaning of given word in English.",
                "options":["Good Morning","Good Evening", "Good Bye"],
                "correctAnswer":"Good Morning",
                "question":[
                  {
                    "word":"Guten","translation":"Good",
                  },
                  {
                    "word":"Morgen","translation":"Morning"
                  }
                ]
              },
              {
              "instruction":"Translate the given word in German.",
                "options":["zwei","eins", "drei"],
                "correctAnswer":"drei",
                "question":[
                  {
                    "word":"3","translation":"drei",
                  },
                ]
              },
              {
                "instruction":"What is the German word for Dog",
                "options":["Katze","Hund","Fisch"],
                "correctAnswer":"Hund",
                "question":[
                    {
                        "word":"Dog","translation":"Hund",  
                    }
                  ]
              }
            ]



            Do not generate any escape characters and options must never be empty. The instructions must not include the question.
              `,
            },
            {
              role: 'user',
              content: `I am learning ${lesson.module.learningPath.language.name} for ${lesson.module.learningPath.reason} and ${lesson.module.learningPath.knowledge}. Please generate ${lesson.questionsCount} questions for me.`,
            },
          ],
        });
        const startTime = new Date().getTime();

        await prisma.$transaction([
          prisma.question.createMany({
            data: (data.object as z.infer<typeof questions_schema>).map(
              (question, idx) => ({
                correctAnswer: question.correctAnswer,
                instruction: question.instruction,
                id: `question_${createId()}`,
                lessonId: lesson.id,
                question: question.questions,
                options: question.options,
                type: question.type,
                createdAt: new Date(startTime + 1000 * idx),
              }),
            ),
          }),
          prisma.lesson.update({
            where: { id: lesson.id },
            data: { questionsStatus: 'generated' },
          }),
        ]);
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
          },
        });
        const messages: Parameters<
          Awaited<typeof this.geminiService.generateObject>
        >['0']['messages'] = [
          {
            role: 'system',
            content: `
Generate a JSON structure for a ${learningPath.language.name} language learning program. The program should consist of 10 modules, each containing at least 3 lessons. Each lesson should a name, description and a "questionsCount" which should be equal to the no of questions that lesson must have. Do not use special characters in names and descriptions. The name and descriptions must be useful and shouldn't include words like "Module 1". The description should not start with "This Module covers" or "This lesson covers".

User wants to learn ${learningPath.language.name} for ${learningPath.reason} and ${learningPath.knowledge}.
 
User has already studied ${learningPath.modules.join(', ')}

Do not generate already generated modules.

Only generate array of modules and no escape characters. 

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
                    })),
                  },
                },
              },
            });
          }
        });
         await pusher.trigger(
          'modules',
          'module_generated',
          request.userId,
        );
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
              },
            },
            lessons: {
              select: {
                name: true,
                description: true,
                questionsCount: true,
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
Generate a JSON structure for lessons belonging to ${module.learningPath.language.name} language learning program. You must generate 4 lessons. Each lesson should have a name, description and a "questionsCount" which should be equal to the no of questions that lesson must have. Do not use special characters in names and descriptions. The name and descriptions must be useful and shouldn't include words like "Module 1". The description should not start with "This Module covers" or "This lesson covers".

User wants to learn ${module.learningPath.language.name} for ${module.learningPath.reason} and ${module.learningPath.knowledge}.
 
User has already studied ${module.lessons.join('\n, ')}

Do not generate already generated lessons.

Only generate array of lessons and no escape characters. 

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
            })),
          });
        });
         await pusher.trigger(
          'modules',
          'module_generated',
          request.userId,
        );
      }
      else{

      const path = await prisma.learningPath.findFirst({
        include: { language: true },
        where: { id: String(body.id) },
      });
      if (!path) return;

      const data = await this.geminiService.generateObject({
        schema: learning_path_schema,
        messages: [
          {
            role: 'system',
            content: `Generate a JSON structure for a ${path.language.name} language learning program. The program should consist of five modules, each containing at least 6 lessons. Each lesson should a name, description and a "questionsCount" which should be equal to the no of questions that lesson must have. Do not use special characters in names and descriptions. The name and descriptions must be useful and shouldn't include words like "Module 1". The description should not start with "This Module covers" or "This lesson covers". Do not generated words like "pronunciation"`,
          },

          {
            role: 'user',
            content: `I want to learn ${path.language.name} and ${path.knowledge}. I want to learn ${path.language.name} for ${path.reason}`,
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
      console.log(error);
      await queue.addToQueueWithPriority({
        id: body.id,
        type: body.type,
      });
    }
  }
}
