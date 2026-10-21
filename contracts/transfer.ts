import { parseArgs } from 'node:util';
import {
    parseEther,
    parseGwei,
} from 'viem';
import { buildClients } from './utils/chain';
import {
    parseAddress,
    parseChainId,
    parseHex,
    runIfMain,
} from './utils/cli';
import { waitForSuccess } from './utils/tx';

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

    // Create the clients used to send transactions
    const {
        publicClient,
        walletClient,
    } = buildClients(
        {
            chainId: parseChainId(values['chain-id']!),
            chainName: values['chain-name']!,
            rpcUrl: values['rpc-url']!,
        },
        parseHex('sender-key', values['sender-key']!, 32),
    );

    // Execute the transaction (equivalent to cast send)
    const hash = await walletClient.sendTransaction({
        to: parseAddress('receiver-address', values['receiver-address']!),
        value: parseEther('10'),
        gas: 21000n,
        maxPriorityFeePerGas: parseGwei('1'),
        maxFeePerGas: parseGwei('10'), // Note: corresponds to the gas price in an EIP-1559 tx
    });

    console.log('Transaction hash:', hash);

    const receipt = await waitForSuccess(publicClient, hash, 'Transfer failed');

    console.log(`Transfer succeded (block ${receipt.blockNumber}).`);
}

runIfMain(module, () => main());
