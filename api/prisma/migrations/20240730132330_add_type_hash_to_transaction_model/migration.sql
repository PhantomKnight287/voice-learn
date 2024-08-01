-- CreateIndex
CREATE INDEX "Transaction_purchaseToken_idx" ON "Transaction" USING HASH ("purchaseToken");
