/*
  Warnings:

  - You are about to drop the column `tier` on the `Voice` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Voice" DROP COLUMN "tier",
ADD COLUMN     "tiers" "Tiers"[] DEFAULT ARRAY['free']::"Tiers"[];
