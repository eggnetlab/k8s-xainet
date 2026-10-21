import {
    Hex,
    isAddress,
    isHex,
} from 'viem';

/**
 * Runs `main` only if the file is launched directly (CommonJS),
 * printing the error message and exiting with code 1 on failure.
 */
export function runIfMain(mod: NodeJS.Module, main: () => Promise<unknown>): void {
    if (require.main === mod) {
        main()
            .catch((err) => {
                console.error(err instanceof Error ? err.message : err);
                process.exit(1);
            });
    }
}

/** Parses a positive integer option (e.g. a chain id). */
export function parseChainId(value: string): number {
    const chainId = Number(value);
    if (!Number.isSafeInteger(chainId) || chainId <= 0) {
        throw new Error(`Invalid chain-id: "${value}" (expected a positive integer).`);
    }
    return chainId;
}

/** Validates a hex string, optionally enforcing its size in bytes. */
export function parseHex(name: string, value: string, sizeBytes?: number): Hex {
    if (!isHex(value, {strict: true})) {
        throw new Error(`Invalid ${name}: expected a 0x-prefixed hex string.`);
    }
    if (sizeBytes !== undefined && value.length !== 2 + sizeBytes * 2) {
        throw new Error(`Invalid ${name}: expected ${sizeBytes} bytes.`);
    }
    return value;
}

/** Validates an EVM address. */
export function parseAddress(name: string, value: string): Hex {
    if (!isAddress(value, {strict: false})) {
        throw new Error(`Invalid ${name}: "${value}" is not a valid address.`);
    }
    return value as Hex;
}
