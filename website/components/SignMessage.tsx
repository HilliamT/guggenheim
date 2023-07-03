import * as React from 'react'
import { recoverMessageAddress } from 'viem'
import { useSignMessage } from 'wagmi'
import { DutchAuctionConfig } from '../types'

export function SignMessage({ signMessageData }) {
    const recoveredAddress = React.useRef<string>()
    const { data, error, isLoading, signMessage, variables } = useSignMessage()

    React.useEffect(() => {
        ; (async () => {
            if (variables?.message && signMessageData) {
                const recoveredAddress = await recoverMessageAddress({
                    message: variables?.message,
                    signature: signMessageData,
                })

                console.log(recoveredAddress);
            }
        })()
    }, [signMessageData, variables?.message])

    let submittedConfig: DutchAuctionConfig = {
        addressOfNft: "",
        tokenIdOfNft: 1,
        initialPrice: 2,
        startBlock: 3,
        endBlock: 8,
        blockDecayRate: 10
    }

    return (
        <form
            onSubmit={(event) => {
                event.preventDefault()
                const formData = new FormData(event.target)
                const message = formData.get('message')
                signMessage({
                    message: JSON.stringify(submittedConfig)
                })
            }}
        >
            <label htmlFor="message">Enter a message to sign</label>
            <textarea
                id="message"
                name="message"
                placeholder="The quick brown fox…"
            />
            <button disabled={isLoading}>
                {isLoading ? 'Check Wallet' : 'Sign Message'}
            </button>

            {data && (
                <div>
                    <div>Recovered Address: {recoveredAddress.current}</div>
                    <div>Signature: {data}</div>
                </div>
            )}

            {error && <div>{error.message}</div>}
        </form>
    )
}
