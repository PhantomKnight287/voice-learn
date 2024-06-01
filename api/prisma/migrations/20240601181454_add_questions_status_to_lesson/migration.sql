-- CreateEnum
CREATE TYPE "QuestionsStatus" AS ENUM ('not_generated', 'generated');

-- AlterTable
ALTER TABLE "Lesson" ADD COLUMN     "questionsStatus" "QuestionsStatus" NOT NULL DEFAULT 'not_generated';
