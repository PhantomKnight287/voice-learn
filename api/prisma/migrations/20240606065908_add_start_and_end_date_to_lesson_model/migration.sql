/*
  Warnings:

  - You are about to drop the column `incorrectAnswersCount` on the `Lesson` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Lesson" DROP COLUMN "incorrectAnswersCount",
ADD COLUMN     "endDate" TIMESTAMP(3),
ADD COLUMN     "incorrectAnswers" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "startDate" TIMESTAMP(3);
