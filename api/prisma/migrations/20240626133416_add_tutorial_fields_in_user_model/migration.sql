-- AlterTable
ALTER TABLE "User" ADD COLUMN     "chatScreenTutorialShwn" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "homeScreenTutorialShown" BOOLEAN NOT NULL DEFAULT false;
