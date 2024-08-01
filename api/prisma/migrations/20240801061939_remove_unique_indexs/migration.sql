/*
  Warnings:

  - You are about to drop the column `purchaseTokenHash` on the `Transaction` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "Transaction_purchaseTokenHash_idx";

-- DropIndex
DROP INDEX "Transaction_purchaseTokenHash_key";

-- DropIndex
DROP INDEX "Transaction_purchaseToken_key";

-- AlterTable
ALTER TABLE "Transaction" DROP COLUMN "purchaseTokenHash";
