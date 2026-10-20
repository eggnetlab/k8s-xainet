import { parseArgs } from 'node:util';
import {
    createPublicClient,
    createWalletClient,
    defineChain,
    http,
    parseEther,
    parseGwei,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

async function main(argv: string[] = process.argv.slice(2)) {
    const {values} = parseArgs({
        args: argv,
        options: {
            'chain-id': {
                type: 'string',
                required: true,
            },
            'chain-name': {
                type: 'string',
                required: true,
            },
            'rpc-url': {
                type: 'string',
                required: true,
            },
            'sender-key': {
                type: 'string',
                required: true,
            },
            'receiver-address': {
                type: 'string',
                required: true,
            },

        },
    });

    const privateChain = defineChain({
        id: Number(values['chain-id']!),
        name: values['chain-name']!,
        nativeCurrency: {
            name: 'Ether',
            symbol: 'ETH',
            decimals: 18,
        },
        rpcUrls: {
            default: {http: [values['rpc-url']!]}, // RPC of your L2
        },
    });

    // Create the client used to send transactions
    const walletClient = createWalletClient({
        account: privateKeyToAccount(values['sender-key']! as `0x${string}`),
        chain: privateChain,
        transport: http(),
    });

    // Execute the transaction (equivalent to cast send)
    const hash = await walletClient.sendTransaction({
        to: values['receiver-address']! as `0x${string}`,
        value: parseEther('10'),
        gas: 21000n,
        maxPriorityFeePerGas: parseGwei('1'),
        maxFeePerGas: parseGwei('10'), // Note: corresponds to the gas price in an EIP-1559 tx
    });

    console.log('Transaction hash:', hash);

    const publicClient = createPublicClient({transport: http(values['rpc-url']!)});

    const receipt = await publicClient.waitForTransactionReceipt({hash: hash});
    if (!receipt || receipt.status !== 'success') {
        throw new Error('Transfer failed');
    }

    console.log(`Transfer succeded (block ${receipt.blockNumber}).`);
}

// Run main() only if the file is launched directly (CommonJS)
if (require.main === module) {
    main()
        .catch((err) => {
            console.error(err instanceof Error ? err.message : err);
            process.exit(1);
        });
}