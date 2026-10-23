import { parseArgs } from 'node:util';
import {
    createPublicClient,
    getCreateAddress,
    type Hex,
    http,
    keccak256,
    recoverAddress,
    toHex,
    toRlp,
} from 'viem';
import { runIfMain } from './utils/cli';
import {
    assertCodeDeployed,
    assertFunds,
    hasCode,
    waitForSuccess,
} from './utils/tx';

/**
 * Generates a pre-signed EIP-155 legacy transaction to deploy the
 * "Deterministic Deployment Proxy" (Arachnid) on a network with a custom chainId,
 * and (with --deploy) broadcasts it, verifying the outcome.
 *
 * Principle: r/s are arbitrary values (0x2222...), the EIP-155 signing hash
 * (which includes the chainId) is built and, via ecrecover, the address that
 * would have produced that signature is derived. No real private key is involved.
 */

    // Proxy bytecode (Arachnid deterministic-deployment-proxy)
const INIT_CODE: Hex =
        '0x604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3';

const GAS_PRICE = 100_000_000_000n; // 100 gwei
const GAS_LIMIT = 100_000n;
const NONCE = 0n;
const VALUE = 0n;

// Arbitrary values for r and s (same scheme as Arachnid/Safe)
const R: Hex = `0x${'22'.repeat(32)}`;
const S: Hex = `0x${'22'.repeat(32)}`;

interface PresignedTx {
    chainId: bigint;
    gasPrice: bigint;
    gasLimit: bigint;
    signerAddress: Hex;
    transaction: Hex;
    proxyAddress: Hex;
    fundingRequired: bigint;
}

interface DeployResult {
    alreadyDeployed: boolean;
    proxyAddress: Hex;
    txHash?: Hex;
    blockNumber?: bigint;
}

const encodeField = (value: bigint): Hex => (value === 0n ? '0x' : toHex(value));

function buildUnsignedFields(chainId: bigint): Hex[] {
    return [
        encodeField(NONCE),
        encodeField(GAS_PRICE),
        encodeField(GAS_LIMIT),
        '0x', // to: empty, contract creation
        encodeField(VALUE),
        INIT_CODE,
        encodeField(chainId),
        '0x', // placeholder r for the EIP-155 signing hash
        '0x', // placeholder s
    ];
}

function buildSignedFields(v: bigint): Hex[] {
    return [
        encodeField(NONCE),
        encodeField(GAS_PRICE),
        encodeField(GAS_LIMIT),
        '0x',
        encodeField(VALUE),
        INIT_CODE,
        encodeField(v),
        R,
        S,
    ];
}

async function computePresignedTx(chainId: bigint): Promise<PresignedTx> {
    // 1. Hash to "sign" (EIP-155): rlp([nonce, gasPrice, gasLimit, to, value, data, chainId, 0, 0])
    const signingHash = keccak256(toRlp(buildUnsignedFields(chainId)));

    // 2. Try both values of v (chainId*2 + 35 or + 36) and recover the signer with ecrecover.
    const candidates: {
        v: bigint;
        signer: Hex
    }[] = [];
    for (const parity of [
        0n,
        1n,
    ]) {
        const v = chainId * 2n + 35n + parity;
        try {
            const signer = await recoverAddress({
                hash: signingHash,
                signature: {
                    r: R,
                    s: S,
                    v: 27n + parity,
                },
            });
            candidates.push({
                v,
                signer,
            });
        } catch {
            // invalid r/s/parity combination on the secp256k1 curve, discarded
        }
    }

    if (candidates.length === 0) {
        throw new Error('No valid combination found, change R/S and try again.');
    }

    // Any valid combination will do: take the first one.
    const {
        v,
        signer,
    } = candidates[0];

    // 3. Signed transaction (RLP with v/r/s)
    const transaction = toRlp(buildSignedFields(v));

    // 4. Resulting contract address (standard CREATE, nonce=0)
    const proxyAddress = getCreateAddress({
        from: signer,
        nonce: 0n,
    });

    return {
        chainId,
        gasPrice: GAS_PRICE,
        gasLimit: GAS_LIMIT,
        signerAddress: signer,
        transaction,
        proxyAddress,
        fundingRequired: GAS_PRICE * GAS_LIMIT,
    };
}

function serializePresignedTx(result: PresignedTx): Record<string, string> {
    return {
        chainId: result.chainId.toString(),
        gasPrice: result.gasPrice.toString(),
        gasLimit: result.gasLimit.toString(),
        signerAddress: result.signerAddress,
        transaction: result.transaction,
        proxyAddress: result.proxyAddress,
        fundingRequired: `${result.fundingRequired} wei`,
    };
}

async function generate(chainId: bigint): Promise<PresignedTx> {
    return computePresignedTx(chainId);
}

async function deploy(
    chainId: bigint,
    rpcUrl: string,
    log: (msg: string) => void = console.log,
): Promise<DeployResult> {
    const result = await computePresignedTx(chainId);
    const client = createPublicClient({transport: http(rpcUrl)});

    // Preliminary check: is the proxy already present?
    if (await hasCode(client, result.proxyAddress)) {
        log(`Proxy already present at ${result.proxyAddress}, no deployment needed.`);
        return {
            alreadyDeployed: true,
            proxyAddress: result.proxyAddress,
        };
    }

    // Check the funds of the throwaway signer
    await assertFunds(client, result.signerAddress, result.fundingRequired);

    log(`Broadcasting deploy tx (chainId=${result.chainId})...`);
    const txHash = await client.sendRawTransaction({
        serializedTransaction: result.transaction,
    });
    log(`Tx hash: ${txHash}`);

    const receipt = await waitForSuccess(client, txHash, 'Deployment failed (revert or missing receipt).');
    await assertCodeDeployed(client, result.proxyAddress);

    log(`Proxy successfully deployed to ${result.proxyAddress} (block ${receipt.blockNumber}).`);
    return {
        alreadyDeployed: false,
        proxyAddress: result.proxyAddress,
        txHash,
        blockNumber: receipt.blockNumber,
    };
}

async function main(argv: string[] = process.argv.slice(2)): Promise<void> {
    const {values} = parseArgs({
        args: argv,
        options: {
            generate: {
                type: 'boolean',
                short: 'g',
                default: false,
            },
            deploy: {
                type: 'boolean',
                short: 'd',
                default: false,
            },
            'chain-id': {type: 'string'},
            'rpc-url': {type: 'string'},
        },
    });

    if (!values.generate && !values.deploy) {
        throw new Error('Specify one of the two options: --generate or --deploy.');
    }
    if (values.generate && values.deploy) {
        throw new Error('Options --generate and --deploy are mutually exclusive.');
    }

    const chainIdRaw = values['chain-id'] ?? process.env.CHAIN_ID;
    if (!chainIdRaw) {
        throw new Error('Unable to determine chainId (use --chain-id or CHAIN_ID).');
    }
    const chainId = BigInt(chainIdRaw);

    if (values.generate) {
        const result = await generate(chainId);
        console.log(JSON.stringify(serializePresignedTx(result), null, 2));
        return;
    }

    const rpcUrl = values['rpc-url'] ?? process.env.SEQUENCER_URL;
    if (!rpcUrl) {
        throw new Error('Unable to determine RPC node URL (use --rpc-url or SEQUENCER_URL).');
    }
    await deploy(chainId, rpcUrl);
}

runIfMain(module, () => main());
