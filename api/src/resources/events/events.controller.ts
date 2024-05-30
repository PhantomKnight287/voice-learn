import { Controller } from '@nestjs/common';
import { EventsService } from './events.service';
import { OnEvent } from '@nestjs/event-emitter';
import { CreatePathEvent } from 'src/events';
import { prisma } from 'src/db';
import { GeminiService } from 'src/services/gemini/gemini.service';
import { learning_path_schema } from 'src/schemas';
import { z } from 'zod';
import { createId } from '@paralleldrive/cuid2';

@Controller('events')
export class EventsController {
  constructor(
    private readonly eventsService: EventsService,
    private readonly geminiService: GeminiService,
  ) {}

  @OnEvent('learning_path.create')
  async createLearningPath(body: CreatePathEvent) {
    console.log(`Got event with id ${body.id}`);
    const path = await prisma.learningPath.findFirst({
      include: { language: true },
      where: { id: body.id },
    });

    const data = await this.geminiService.generateObject({
      schema: learning_path_schema,
      messages: [
        {
          role: 'system',
          content: `You are a language teacher proficient in ${path.language.name}. You have to generate the language learning modules as per user's preferences. The correctAnswer must be one from options. The name of modules must be in english. The question in questions must be an array of object of each word where word will be actual word in ${path.language.name} and translation will be word in english. For example: question:[{word:"guten",translation:"good"},{word:"tag",translation:"day"}]. You must generate all types of questions given in schema. Generate a detailed Learning Path for the user. You are free to make it long but make sure it explains everything well.`,
        },
        {
          role: 'user',
          content: `I want to learn ${path.language.name} and ${path.knowledge}. I want to learn ${path.language.name} to ${path.reason}.`,
        },
      ],
    });
    const object: z.infer<typeof learning_path_schema> = data.object;

    for (const path of object.paths) {
      await prisma.learningPath.update({
        where: { id: body.id },
        data: {
          modules: {
            create: path.modules.map((module) => ({
              name: module.name,
              id: `module_${createId()}`,
              description: module.description,
            })),
          },
          type: 'generated',
        },
      });
      for (const pathModule of path.modules) {
        const module = await prisma.module.findFirst({
          where: { name: pathModule.name, learningPathId: body.id },
        });
        if (!module) continue;
        await prisma.module.update({
          where: { id: module.id },
          data: {
            lessons: {
              create: pathModule.lessons.map((lesson) => ({
                name: lesson.name,
                id: `lesson_${createId()}`,
              })),
            },
          },
        });
        for (const lesson of pathModule.lessons) {
          const dbLesson = await prisma.lesson.findFirst({
            where: { moduleId: module.id },
          });
          await prisma.lesson.update({
            data: {
              questions: {
                create: lesson.questions.map((question) => ({
                  id: `question_${createId()}`,
                  correctAnswer: question.correctAnswer,
                  type: question.type,
                  options: question.options,
                  question: question.question,
                })),
              },
            },
            where: { id: dbLesson.id },
          });
        }
      }
    }
    console.log('written');
  }
}
