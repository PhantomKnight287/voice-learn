/*
  Warnings:

  - You are about to drop the column `lessonId` on the `GenerationRequest` table. All the data in the column will be lost.

*/
-- DropForeignKey
ALTER TABLE "GenerationRequest" DROP CONSTRAINT "GenerationRequest_lessonId_fkey";

-- AlterTable
ALTER TABLE "GenerationRequest" DROP COLUMN "lessonId",
ADD COLUMN     "moduleId" TEXT;

-- AddForeignKey
ALTER TABLE "GenerationRequest" ADD CONSTRAINT "GenerationRequest_moduleId_fkey" FOREIGN KEY ("moduleId") REFERENCES "Module"("id") ON DELETE SET NULL ON UPDATE CASCADE;
