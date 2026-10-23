import {
    abi as EntryPointAbi,
    bytecode as EntryPointBytecode,
    deployedBytecode as EntryPointDeployedBytecode,
} from '@account-abstraction/contracts/artifacts/EntryPoint.json';
import { parseArgs } from 'node:util';
import {
    Abi,
    encodeDeployData,
    getCreate2Address,
    SendTransactionParameters,
} from 'viem';
import { buildClients } from './utils/chain';
import {
    parseAddress,
    parseChainId,
    parseHex,
    runIfMain,
} from './utils/cli';
import {
    assertCodeDeployed,
    hasCode,
    waitForSuccess,
} from './utils/tx';

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

    const {
        publicClient,
        walletClient,
    } = buildClients(
        {
            chainId: parseChainId(values['chain-id']!),
            chainName: values['chain-name']!,
            rpcUrl: values['rpc-url']!,
        },
        parseHex('private-key', values['private-key']!, 32),
    );

    const contractDeployData = encodeDeployData({
        abi: artifact.abi,
        bytecode: artifact.bytecode,
        args: [],
    });

    const salt = parseHex('salt', values['salt']!, 32);
    const factoryAddress = parseAddress('factory-address', values['factory-address']!);

    const contractAddress = getCreate2Address({
        from: factoryAddress,
        bytecode: contractDeployData,
        salt,
    });

    // Check whether it is already present in the L2 state
    if (await hasCode(publicClient, contractAddress)) {
        console.log(`Entrypoint is already deployed at the address ${contractAddress}`);
        return;
    }

    const txHash = await walletClient.sendTransaction({
        to: factoryAddress,
        data: `0x${salt.slice(2)}${contractDeployData.slice(2)}` as `0x${string}`,
    } as SendTransactionParameters);
    console.debug(`[Tx] Transaction sent: ${txHash}`);

    const receipt = await waitForSuccess(publicClient, txHash, `Deployment failed: tx ${txHash} reverted`);
    await assertCodeDeployed(publicClient, contractAddress);

    console.log(`${artifact.name} successfully deployed to ${contractAddress} (block ${receipt.blockNumber}).`);
}

runIfMain(module, () => main());
