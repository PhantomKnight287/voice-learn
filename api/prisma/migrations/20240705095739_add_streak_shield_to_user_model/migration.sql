-- CreateEnum
CREATE TYPE "StreakType" AS ENUM ('active', 'shielded');

-- AlterTable
ALTER TABLE "Streak" ADD COLUMN     "type" "StreakType" NOT NULL DEFAULT 'active';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "streakShields" INTEGER NOT NULL DEFAULT 2;
