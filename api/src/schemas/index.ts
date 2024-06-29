import { QuestionType } from '@prisma/client';
import { z } from 'zod';

export const learning_path_schema = z.object({
  paths: z.array(
    z.object({
      type: z.literal('generated'),
      modules: z
        .array(
          z.object({
            name: z
              .string()
              .describe('The name of the module, must be in english'),
            description: z
              .string()
              .describe(
                'The description of the module, must be in english. Must tell users what they will learn in this module.',
              ),
            lessons: z.array(
              z.object({
                name: z
                  .string()
                  .describe(
                    'The name of the lesson, must be in english and as short as possible.',
                  ),
                questionsCount: z.number(),
                description: z.string(),
                explanation: z.string(),
              }),
            ),
          }),
        )
        .describe('The modules for user.'),
    }),
  ),
});

export const questions_schema = z.array(
  z.object({
    instruction: z.string(),
    type: z.nativeEnum(QuestionType),
    options: z.array(z.string()),
    correctAnswer: z.string(),
    questions: z.array(
      z.object({
        word: z.string(),
        translation: z.string(),
        new: z.boolean().optional(),
      }),
    ),
  }),
);

export const modules_schema = z
  .array(
    z.object({
      name: z.string().describe('The name of the module, must be in english'),
      description: z
        .string()
        .describe(
          'The description of the module, must be in english. Must tell users what they will learn in this module.',
        ),
      lessons: z.array(
        z.object({
          name: z
            .string()
            .describe(
              'The name of the lesson, must be in english and as short as possible.',
            ),

          questionsCount: z.number(),
          description: z.string(),
        }),
      ),
    }),
  )
  .describe('The modules for user.');

export const lessons_schema = z.array(
  z.object({
    name: z.string(),
    questionsCount: z.number(),
    description: z.string(),
  }),
);
