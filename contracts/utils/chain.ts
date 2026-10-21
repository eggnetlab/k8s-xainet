import {
    createPublicClient,
    createWalletClient,
    defineChain,
    Hex,
    http,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

export interface ChainOptions {
    chainId: number;
    chainName: string;
    rpcUrl: string;
}

export function buildChain({
                               chainId,
                               chainName,
                               rpcUrl,
                           }: ChainOptions) {
    return defineChain({
        id: chainId,
        name: chainName,
        nativeCurrency: {
            name: 'Ether',
            symbol: 'ETH',
            decimals: 18,
        },
        rpcUrls: {
            default: {http: [rpcUrl]}, // RPC of your L2
        },
    });
}

export function buildClients(options: ChainOptions, privateKey: Hex) {
    const publicClient = createPublicClient({transport: http(options.rpcUrl)});
    const walletClient = createWalletClient({
        account: privateKeyToAccount(privateKey),
        chain: buildChain(options),
        transport: http(),
    });
    return {
        publicClient,
        walletClient,
    };
}
