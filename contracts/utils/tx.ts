import {
    Hex,
    PublicClient,
    TransactionReceipt,
} from 'viem';

/** Returns true if there is deployed bytecode at the given address. */
export async function hasCode(client: PublicClient, address: Hex): Promise<boolean> {
    const code = await client.getCode({address});
    return !!code && code !== '0x';
}

/** Waits for the receipt and throws if the transaction did not succeed. */
export async function waitForSuccess(
    client: PublicClient,
    hash: Hex,
    errorMessage: string,
): Promise<TransactionReceipt> {
    const receipt = await client.waitForTransactionReceipt({hash});
    if (!receipt || receipt.status !== 'success') {
        throw new Error(errorMessage);
    }
    return receipt;
}

/** Throws if no bytecode is found at the address after a deployment. */
export async function assertCodeDeployed(client: PublicClient, address: Hex): Promise<void> {
    if (!(await hasCode(client, address))) {
        throw new Error(
            `Transaction included, but no bytecode found at ${address}. ` +
            `Verify that the network supports standard CREATE2/opcodes and that the chainId is correct.`,
        );
    }
}

/** Throws if the account balance is below the required amount. */
export async function assertFunds(client: PublicClient, address: Hex, required: bigint): Promise<void> {
    const balance = await client.getBalance({address});
    if (balance < required) {
        throw new Error(
            `Insufficient funds on ${address}: ` +
            `available ${balance} wei, required ${required} wei.`,
        );
    }
}
