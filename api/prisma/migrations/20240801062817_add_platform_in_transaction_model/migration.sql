-- CreateEnum
CREATE TYPE "Platform" AS ENUM ('android', 'ios');

-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "platform" "Platform" NOT NULL DEFAULT 'ios';
