/*
  Warnings:

  - You are about to drop the column `flag` on the `Language` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[flagUrl]` on the table `Language` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `flagUrl` to the `Language` table without a default value. This is not possible if the table is not empty.
  - Added the required column `flagUrlExpireTimestamp` to the `Language` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX "Language_flag_key";

-- AlterTable
ALTER TABLE "Language" DROP COLUMN "flag",
ADD COLUMN     "flagUrl" TEXT NOT NULL,
ADD COLUMN     "flagUrlExpireTimestamp" TIMESTAMP(3) NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "Language_flagUrl_key" ON "Language"("flagUrl");
