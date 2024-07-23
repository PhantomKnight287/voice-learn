-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('ALERT', 'WARNING', 'INFO', 'SUCCESS');

-- AlterTable
ALTER TABLE "Notification" ADD COLUMN     "type" "NotificationType";
