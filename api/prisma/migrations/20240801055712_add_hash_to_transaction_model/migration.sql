/*
  Warnings:

  - A unique constraint covering the columns `[purchaseTokenHash]` on the table `Transaction` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "purchaseTokenHash" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Transaction_purchaseTokenHash_key" ON "Transaction"("purchaseTokenHash");
