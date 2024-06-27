/*
  Warnings:

  - You are about to drop the column `chatScreenTutorialShwn` on the `User` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "User" DROP COLUMN "chatScreenTutorialShwn",
ADD COLUMN     "chatScreenTutorialShown" BOOLEAN NOT NULL DEFAULT false;
