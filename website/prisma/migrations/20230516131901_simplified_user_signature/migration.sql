/*
  Warnings:

  - You are about to drop the column `signatureR` on the `DutchAuction` table. All the data in the column will be lost.
  - You are about to drop the column `signatureS` on the `DutchAuction` table. All the data in the column will be lost.
  - You are about to drop the column `signatureV` on the `DutchAuction` table. All the data in the column will be lost.
  - Added the required column `userSignature` to the `DutchAuction` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "DutchAuction" DROP COLUMN "signatureR",
DROP COLUMN "signatureS",
DROP COLUMN "signatureV",
ADD COLUMN     "userSignature" TEXT NOT NULL;
