-- CreateTable
CREATE TABLE "DutchAuction" (
    "seller" TEXT NOT NULL,
    "addressOfNft" TEXT NOT NULL,
    "tokenIdOfNft" INTEGER NOT NULL,
    "initialPrice" INTEGER NOT NULL,
    "startBlock" INTEGER NOT NULL,
    "endBlock" INTEGER NOT NULL,
    "blockDecayRate" INTEGER NOT NULL,
    "signatureV" INTEGER NOT NULL,
    "signatureR" TEXT NOT NULL,
    "signatureS" TEXT NOT NULL,

    CONSTRAINT "DutchAuction_pkey" PRIMARY KEY ("seller","addressOfNft","tokenIdOfNft")
);
