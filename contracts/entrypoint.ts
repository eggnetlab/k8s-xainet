import {
    abi as EntryPointAbi,
    bytecode as EntryPointBytecode,
    deployedBytecode as EntryPointDeployedBytecode,
} from '@account-abstraction/contracts/artifacts/EntryPoint.json';
import { parseArgs } from 'node:util';
import {
    Abi,
    createPublicClient,
    createWalletClient,
    defineChain,
    encodeDeployData,
    getCreate2Address,
    http,
    SendTransactionParameters,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

export async function main(argv: string[] = process.argv.slice(2)) {
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
            'private-key': {
                type: 'string',
                required: true,
            },
            'factory-address': {
                type: 'string',
                required: true,
            },
            'salt': {
                type: 'string',
                required: true,
            },
        },
    });

    const artifact: any = {
        name: 'EntryPoint',
        abi: EntryPointAbi as Abi,
        bytecode: EntryPointBytecode as `0x${string}`,
        deployedBytecode: EntryPointDeployedBytecode as `0x${string}`,
    };

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

    const publicClient = createPublicClient({transport: http(values['rpc-url']!)});

    const walletClient = createWalletClient({
        account: privateKeyToAccount(values['private-key']! as `0x${string}`),
        chain: privateChain,
        transport: http(),
    });

    const contractDeployData = encodeDeployData({
        abi: artifact.abi,
        bytecode: artifact.bytecode,
        args: [],
    });

    const salt = values['salt']! as `0x${string}`,
        factoryAddress: `0x${string}` = values['factory-address']! as `0x${string}`;

    const contractAddress = getCreate2Address({
        from: factoryAddress,
        bytecode: contractDeployData,
        salt,
    });

    // Check whether it is already present in the L2 state
    const code = await publicClient.getCode({address: contractAddress});
    if (code && code !== '0x') {
        console.log(`Entrypoint is already deployed at the address ${contractAddress}`);
        return;
    }

    const txHash = await walletClient.sendTransaction({
        to: factoryAddress,
        data: `0x${salt?.slice(2)}${contractDeployData.slice(2)}` as `0x${string}`,
    } as SendTransactionParameters);
    console.debug(`[Tx] Transaction sent: ${txHash}`);

    const receipt = await publicClient.waitForTransactionReceipt({hash: txHash});

    if (receipt.status !== 'success') {
        throw new Error(`Deployment failed: tx ${txHash} reverted`);
    }

    console.log(`${artifact.name} successfully deployed to ${contractAddress} (block ${receipt.blockNumber}).`);
}

// Run main() only if the file is launched directly (CommonJS)
if (require.main === module) {
    main()
        .catch((err) => {
            console.error(err instanceof Error ? err.message : err);
            process.exit(1);
        });
}