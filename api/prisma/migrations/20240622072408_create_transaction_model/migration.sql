-- CreateEnum
CREATE TYPE "TransactionType" AS ENUM ('one_time_product', 'subscription');

-- CreateTable
CREATE TABLE "Transaction" (
    "id" TEXT NOT NULL,
    "purchaseToken" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "notificationType" INTEGER,
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "type" "TransactionType" NOT NULL,
    "userId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Transaction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Transaction_id_key" ON "Transaction"("id");

-- CreateIndex
CREATE UNIQUE INDEX "Transaction_purchaseToken_key" ON "Transaction"("purchaseToken");

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
