-- AlterTable
ALTER TABLE "Lesson" ADD COLUMN     "completed" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "correctAnswers" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "incorrectAnswersCount" INTEGER NOT NULL DEFAULT 0;
