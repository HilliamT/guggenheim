import { z } from "zod";

export interface DutchAuctionConfig {
    addressOfNft: string;
    tokenIdOfNft: number;
    initialPrice: number;
    startBlock: number;
    endBlock: number;
    blockDecayRate: number;
}

export const DutchAuctionConfigSchema = z.object({
    addressOfNft: z.string(),
    tokenIdOfNft: z.number(),
    initialPrice: z.number(),
    startBlock: z.number(),
    endBlock: z.number(),
    blockDecayRate: z.number()
});