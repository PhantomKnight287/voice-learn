import { Controller } from '@nestjs/common';
import { EventsService } from './events.service';
import { OnEvent } from '@nestjs/event-emitter';
import { CreatePathEvent } from 'src/events';
import { prisma } from 'src/db';
import { GeminiService } from 'src/services/gemini/gemini.service';
import {
  learning_path_schema,
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
              content: `Generate a JSON ARRAY structure for questions of ${lesson.module.learningPath.language.name} language learning program and for lesson with name ${lesson.name} and description ${lesson.description}. There must be ${lesson.questionsCount} questions. The "instruction" should be the instruction to student on how to solve the question(for example: Translate this sentence to English.), type must either be 'sentence' or 'select_one'. The "options" array must never be empty. The "correctAnswer" should be the correct answer of the question and should not include any special characters including "...". The "question" can be an empty array if type is 'sentence' else it must be an array of objects of words in question. For example, if question is "Guten Tag" then the "question" array must be [{"word":"guten","translation":"good",},{"word":"tag","translation":"day"}]. Do not return excess whitespace, escape characters and punctuation in your response.
              
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
              }
            ]



            Do not generate any escape characters and options must never be empty.
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
        return await pusher.trigger(
          'modules',
          'module_generated',
          lesson.module.learningPath.userId,
        );
        return;
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
            await tx.module.create({
              data: {
                id: `module_${createId()}`,
                description: module.description,
                name: module.name,
                learningPathId: learningPath.id,
                lessons: {
                  createMany: {
                    data: module.lessons.map((lesson) => ({
                      name: lesson.name,
                      id: `lesson_${createId()}`,
                      completed: false,
                      description: lesson.description,
                      questionsCount: lesson.questionsCount,
                    })),
                  },
                },
              },
            });
          }
        });
        return await pusher.trigger(
          'modules',
          'module_generated',
          request.userId,
        );
      }
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
            // content: `
            // You are a language teacher proficient in ${path.language.name}. Your job is to create lessons for your learners so that they can learn that language.

            // Take a look at each structure of objects and construct your final response accordingly.
            // The final response MUST follow this JSON structure.

            // ---
            // {
            //   "paths":[
            //     {
            //       "type": it will be always "generated",
            //       "modules": an array of Objects where each object is an ModulesObject (take a look at below to see the structure of ModulesObject)
            //     }
            // }
            // ---

            // Here is how ModulesObject will look like:
            // ---
            // {
            //  "name" : name of module
            //  "description": description of module
            //  "lessons": it will be an array of Objects where each object is a LessonsObject (take a look at below to see the structure of LessonsObject)
            // }
            // ---

            // Here is how LessonsObject will look like:
            // ---
            // {
            //  "name": name of lesson
            //  "description": description of lesson
            //  "questions": it will be an array of Objects where each object is a QuestionObject (take a look at below to see the structure of QuestionObject)
            // }
            // ---

            // Here is how QuestionObject will look like:
            // ---
            // {
            //  "type": type of question, it can be "select_one" or "sentence"
            //  "options": if the question type is "select_one" then it will be an array of 4 options else keep it empty array
            //  "instruction": It will be the instruction to user on how to solve a question
            //  "correctAnswer": correct answer of the question
            //  "question": it will be an array of objects where each object have 3 properties: 1) word(a single word in the given language) 2) translation(translation of that single word in English) 3) new (it will be true if the word was already present in other questions else keep it false)
            // }
            // ---

            // Make sure to follow all the instructions given above else the validation will fail. The response must be a valid parsable JSON

            // Note: Each module should have ATLEAST 4 lessons and each lesson should have ATLEAST 8 questions
            // `,
            // content: `You are a language teacher proficient in ${path.language.name}. Your job is to create language learning modules for users based on how much language they already know and for what they want to learn the language.

            // You must return the response as an object. The first object must have a "paths" array which should be objects having "type" key which should always be "generated". The same object where "type" is specified should also have modules, which is an array. It should have at least 5 modules but can be more than 5 in any case. Each module must have a "name" which should be the name in English, a description of the module like what the user will learn in this module. Each module object should have "lessons" which is an array of objects. Each lesson must have a "name" which should be the name in English, a description of the lesson like what the user will learn in this lesson. Each lesson object should have "questions" which is an array of objects. There must be at least 8 questions. Each question should have "type" which can be either 'sentence' or 'select_one', an "instruction" which should tell the user what to do in this question to solve it, an "options" array which should be an array of strings having options (in case of 'sentence', it can be empty) and a "question" array which should have at least 1 object. The object must have a "word" which should be equal to the word in ${path.language.name} and a "translated" which should be equal to the translation of the word in English.`,
            // content: `
            // Create a JSON structure for a basic ${path.language.name} language learning module. The module should include lessons on greetings, numbers, common phrases, and colors. Each lesson should contain multiple-choice questions with options and correct answers. Provide instructions for each question and include translations for the words in the questions and answers.
            // `,
            content: `Generate a JSON structure for a ${path.language.name} language learning program. The program should consist of five modules, each containing at least two lessons. Each lesson should a name, description and a "questionsCount" which should be equal to the no of questions that lesson must have. Do not use special characters in names and descriptions. The name and descriptions must be useful and shouldn't include words like "Module 1". The description should not start with "This Module covers" or "This lesson covers"`,
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

      console.log('generated');
    } catch (error) {
      console.log(error);
      await queue.addToQueueWithPriority({
        id: body.id,
        type: body.type,
      });
    }
  }
}
