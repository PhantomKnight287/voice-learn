-- CreateEnum
CREATE TYPE "PathType" AS ENUM ('generated', 'created');

-- AlterTable
ALTER TABLE "LearningPath" ADD COLUMN     "type" "PathType" NOT NULL DEFAULT 'created';
