/*
  Warnings:

  - You are about to drop the column `audioUrl` on the `Message` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Message" DROP COLUMN "audioUrl",
ADD COLUMN     "attachmentId" TEXT;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_attachmentId_fkey" FOREIGN KEY ("attachmentId") REFERENCES "Upload"("id") ON DELETE SET NULL ON UPDATE CASCADE;
