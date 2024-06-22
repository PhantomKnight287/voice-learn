-- CreateEnum
CREATE TYPE "Tiers" AS ENUM ('epic', 'premium', 'free');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "tier" "Tiers" NOT NULL DEFAULT 'free';

-- AlterTable
ALTER TABLE "Voice" ADD COLUMN     "tier" "Tiers" NOT NULL DEFAULT 'free';
