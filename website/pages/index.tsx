import { createPublicClient, http } from 'viem';
import { createConfig, mainnet, useAccount, useConnect, useDisconnect, WagmiConfig } from 'wagmi';
import { InjectedConnector } from "wagmi/connectors/injected";

const config = createConfig({
    autoConnect: true,
    publicClient: createPublicClient({
        chain: mainnet,
        transport: http()
    }),
});

function Profile() {
    const { address, isConnected } = useAccount()
    const { connect } = useConnect({
        connector: new InjectedConnector(),
    })
    const { disconnect } = useDisconnect()

    if (isConnected)
        return (
            <div>
                Connected to {address}
                <button onClick={() => disconnect()}>Disconnect</button>
            </div>
        )
    return <button onClick={() => connect()}>Connect Wallet</button>
}

export default function App() {
    return (
        <WagmiConfig config={config}>
            <Profile />
        </WagmiConfig>
    )
}