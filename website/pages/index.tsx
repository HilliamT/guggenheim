import { createPublicClient, http } from 'viem';
import { createConfig, mainnet, useAccount, useConnect, useDisconnect, WagmiConfig } from 'wagmi';
import { InjectedConnector } from "wagmi/connectors/injected";
import { SignMessage } from '../components/SignMessage';

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

                <SignMessage />
            </div>
        )
    return <button onClick={() => connect()}>Connect Wallet</button>
}

export default function App() {
    return (
        <div className="flex justify-center font-mono">

            <div id="navigation-bar" className='border-2 border-black fixed p-2 bg-white rounded-xl m-2 flex gap-3 items-center'>
                <div className='font-bold text-xl'>guggenheim</div>
                <div>
                    <WagmiConfig config={config}>
                        <Profile />
                    </WagmiConfig>
                </div>
            </div>

            <div className='grid grid-cols-4 mt-20'>
                <div className='m-8'>
                    <div className='p-8'>
                        <img src={"https://i.seadn.io/gcs/files/cc5ed469ae4ce96b18112a288ad4dd3d.png"} width={200} height={500} />
                    </div>

                    <div className='font-bold'>milady #8471</div>
                    <div>buy: 0.25 eth</div>
                </div>

                <div className='m-8'>
                    <div className='p-8'>
                        <img src={"https://i.seadn.io/gcs/files/cc5ed469ae4ce96b18112a288ad4dd3d.png"} width={200} height={500} />
                    </div>

                    <div className='font-bold'>milady.</div>
                    <div>buy: 0.25 eth</div>
                </div>

                <div className='m-8'>
                    <div className='p-8'>
                        <img src={"https://i.seadn.io/gcs/files/cc5ed469ae4ce96b18112a288ad4dd3d.png"} width={200} height={500} />
                    </div>

                    <div className='font-bold'>milady.</div>
                    <div>buy: 0.25 eth</div>
                </div>

                <div className='m-8'>
                    <div className='p-8'>
                        <img src={"https://i.seadn.io/gcs/files/cc5ed469ae4ce96b18112a288ad4dd3d.png"} width={200} height={500} />
                    </div>

                    <div className='font-bold'>milady.</div>
                    <div>buy: 0.25 eth</div>
                </div>

                <div className='m-8'>
                    <div className='p-8'>
                        <img src={"https://i.seadn.io/gcs/files/cc5ed469ae4ce96b18112a288ad4dd3d.png"} width={200} height={500} />
                    </div>

                    <div className='font-bold'>milady.</div>
                    <div>buy: 0.25 eth</div>
                </div>


                <div className='m-8'>
                    <div className='p-8'>
                        <img src={"https://i.seadn.io/gcs/files/cc5ed469ae4ce96b18112a288ad4dd3d.png"} width={200} height={500} />
                    </div>

                    <div className='font-bold'>milady.</div>
                    <div>buy: 0.25 eth</div>
                </div>

                <div className='m-8'>
                    <div className='p-8'>
                        <img src={"https://i.seadn.io/gcs/files/cc5ed469ae4ce96b18112a288ad4dd3d.png"} width={200} height={500} />
                    </div>

                    <div className='font-bold'>milady.</div>
                    <div>buy: 0.25 eth</div>
                </div>
            </div>
        </div>
    )
}