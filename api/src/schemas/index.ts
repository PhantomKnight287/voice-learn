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
                // questions: z
                //   .array(
                //     z.object({
                //       question: z
                //         .array(
                //           z.object({
                //             translation: z
                //               .string()
                //               .describe('The translation of word in english'),
                //             word: z
                //               .string()
                //               .describe(
                //                 "The actual word in user's selected language",
                //               ),
                //           }),
                //         )
                //         .min(1),
                //       type: z
                //         .nativeEnum(QuestionType)
                //         .describe(
                //           "The type of question. Can be 'select_one' and 'sentence'",
                //         ),
                //       options: z
                //         .array(z.string())
                //         .describe(
                //           "The options array for the question. Applicable for 'select_one' question.",
                //         ),
                //       correctAnswer: z
                //         .string()
                //         .describe('The correct answer of the question'),
                //       instruction: z
                //         .string()
                //         .describe(
                //           'Tell user what to do to solve this question.',
                //         ),
                //     }),
                //   )
                //   .describe('The questions for user to learn and practice'),
                questionsCount: z.number(),
                description: z.string(),
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
