import { QuestionType } from '@prisma/client';
import { z } from 'zod';

export const learning_path_schema = z.object({
  paths: z.array(
    z.object({
      type: z.literal('generated'),
      modules: z.array(
        z.object({
          name: z.string(),
          description: z.string(),
          lessons: z.array(
            z.object({
              name: z.string(),
              questions: z.array(
                z.object({
                  question: z.array(
                    z.object({
                      translation: z.string(),
                      word: z.string(),
                    }),
                  ),
                  type: z.nativeEnum(QuestionType),
                  options: z.array(z.string()),
                  correctAnswer: z.string(),
                }),
              ),
            }),
          ),
        }),
      ),
    }),
  ),
});
