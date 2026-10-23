# contracts

TypeScript scripts (viem) that deploy the deterministic deployment proxy and the ERC-4337 EntryPoint v0.7 on the L2. For the reason why they are needed, and for the license note,
read [docs/contracts.md](../docs/contracts.md).

Normally you run them with `make bc-start` or `make contracts` from the root of the repository. This page is for running them by hand.

## Install

```bash
pnpm install --frozen-lockfile
```

## Scripts

| Command               | Main options                                                                              |
|-----------------------|-------------------------------------------------------------------------------------------|
| `pnpm run generate`   | `--chain-id` (or `CHAIN_ID`)                                                              |
| `pnpm run transfer`   | `--chain-id`, `--chain-name`, `--rpc-url`, `--sender-key`, `--receiver-address`           |
| `pnpm run deploy`     | `--chain-id` (or `CHAIN_ID`), `--rpc-url` (or `SEQUENCER_URL`)                            |
| `pnpm run entrypoint` | `--chain-id`, `--chain-name`, `--rpc-url`, `--private-key`, `--factory-address`, `--salt` |

The values for the `dev` network are in the root `../.env`.

## Change the L2 chain ID

The deterministic deployment proxy depends on the chain ID: a different chain ID gives a different deployer and a different proxy address. If you change the chain ID of the L2, run `generate` with the
new value to get the new proxy values. The command only prints data: it does not send anything and does not need a running network.

```bash
pnpm run generate --chain-id <new chain id>
```

The output is a JSON object. Two fields matter:

| Field in the output | Where it goes                                |
|---------------------|----------------------------------------------|
| `signerAddress`     | `RECEIVER_ADDRESS` in the root `.env`        |
| `proxyAddress`      | `CREATE2_FACTORY_ADDRESS` in the root `.env` |

Then:

1. Set `L2_CHAIN_ID` in the root `.env` and update the other places where the chain ID is written. They are listed in [Configuration](../docs/configuration.md#l2-chain-id).
2. Run `deploy` and `entrypoint` (or the whole start) so that both contracts are deployed for the new chain ID.
3. The EntryPoint address changes too, because it depends on the proxy address. Update it in `k8s/overlays/dev/bundler/configmap.yaml` with the address printed by `entrypoint`, and restart the
   bundler.

If the proxy values in the root `.env` do not match the chain ID, `entrypoint` fails when it checks the deployed code, because the factory does not exist at the configured address.

## Behavior

- `deploy` and `entrypoint` do nothing if the contract is already deployed.
- Both check the deployed code after the transaction and fail if there is none.
- `transfer` sends 10 ETH every time it runs.
- Errors are printed as a short message and the exit code is 1.

## Layout

| Path            | Content                                                                                         |
|-----------------|-------------------------------------------------------------------------------------------------|
| `ddproxy.ts`    | Generates and deploys the deterministic proxy transaction                                       |
| `entrypoint.ts` | Deploys the EntryPoint through the proxy                                                        |
| `transfer.ts`   | Funds the proxy deployer                                                                        |
| `utils/`        | Shared helpers: clients (`chain.ts`), argument parsing (`cli.ts`), transaction checks (`tx.ts`) |

## Type check

The CI runs the type check, and you can run it locally:

```bash
pnpm exec tsc --noEmit
```