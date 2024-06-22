-- AlterTable
ALTER TABLE "Voice" ADD COLUMN     "tier" "Tiers"[] DEFAULT ARRAY['free']::"Tiers"[];
