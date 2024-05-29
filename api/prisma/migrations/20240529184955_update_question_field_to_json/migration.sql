/*
  Warnings:

  - The `question` column on the `Question` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- AlterTable
ALTER TABLE "Question" DROP COLUMN "question",
ADD COLUMN     "question" JSONB[];
