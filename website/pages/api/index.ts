import { DutchAuction, PrismaClient } from '@prisma/client';
import { AlchemyProvider, Wallet } from "ethers";
import { NextApiRequest, NextApiResponse } from "next";
import { recoverMessageAddress } from 'viem';
import { DutchAuctionConfig, DutchAuctionConfigSchema } from '../../types';

const prisma = new PrismaClient()

const wallet = Wallet.createRandom();
const provider = new AlchemyProvider("mainnet", "NGMcvYiHhRkOSvlZtcbCTNyKc3ocdyJg");

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
    // Get signature, config from req.body

    let currentBlockNumber = await provider.getBlockNumber();

    try {
        if (req.method == "GET") {
            // TODO: using query parameters, do some filtering
            let { page } = req.query;

            // console.log(keys);

            const results: (DutchAuction & { apiSignature: string })[] = (await prisma.dutchAuction.findMany({
                where: {
                    // endBlock: {
                    //     gt: currentBlockNumber
                    // },
                    // startBlock: {
                    //     lt: currentBlockNumber
                    // },
                },
                take: 100,
                skip: (((page && typeof page == "string") ? parseInt(page) : 0) * 100),
            })).map(result => {
                return {
                    ...result, apiSignature: wallet.signMessageSync(JSON.stringify({
                        userSignature: result.userSignature,
                        currentBlockNumber
                    }))
                }
            });

            return res.status(200).json(results);

        } else if (req.method == "POST") {
            let { signature: userSignature, config: _config }: { signature: string, config: DutchAuctionConfig } = req.body;

            console.log(userSignature);
            console.log(_config);

            let config = DutchAuctionConfigSchema.parse(_config);
            const message = JSON.stringify(config);

            let { addressOfNft, tokenIdOfNft, initialPrice, startBlock, endBlock, blockDecayRate } = config;

            const recoveredAddress = await recoverMessageAddress({
                message,
                signature: userSignature as any
            });

            console.log(recoveredAddress);

            try {
                await prisma.dutchAuction.create({
                    data: {
                        seller: recoveredAddress,
                        addressOfNft,
                        tokenIdOfNft,
                        initialPrice,
                        startBlock,
                        endBlock,
                        blockDecayRate,
                        userSignature
                    }
                });
            } catch (e: any) {
                if (e.code == "P2002") {
                    return res.status(500).send("Existing listing");
                }
            }

            return res.status(200).send("Howdy");
        } else if (req.method == "PUT") {
            let { signature: userSignature, verification: squaredSignature }: { signature: string, verification: string } = req.body;

            console.log(userSignature);
            console.log(squaredSignature);

            const recoveredAddress = await recoverMessageAddress({
                message: userSignature,
                signature: squaredSignature as any
            });

            try {
                await prisma.dutchAuction.deleteMany({
                    where: {
                        seller: recoveredAddress,
                        userSignature,
                    }
                })
            } catch (e: any) {
                return res.status(500).send("Error")
            }

            return res.status(200).send("OK");
        }

    } catch (e: any) {
        console.log(e);
        return res.status(404).send(e);
    }
}