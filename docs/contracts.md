# Contracts: deterministic proxy and EntryPoint

An ERC-4337 setup needs two contracts on the L2: the deterministic deployment proxy and the EntryPoint. This repository deploys both for **your** chain ID, with scripts in `contracts/`.

## Why they are recreated

Both contracts have well-known addresses, but those addresses are only valid on networks where the contracts were deployed in the standard way. On a custom chain they do not exist.

The addresses depend on the chain ID:

1. The proxy is deployed with a pre-signed legacy transaction. The scripts generate it for your chain ID with replay protection (EIP-155), so its signer, and therefore the address of the proxy, are
   different on every chain ID.
2. The EntryPoint is deployed through the proxy with CREATE2. Its address depends on the proxy address, the salt and the bytecode, so it is not the canonical address either.

Bundlers and SDKs that have the canonical EntryPoint address built in fail on this network, usually with an unclear error. Always configure them with the addresses printed by the scripts.

With the same chain ID, salt and bytecode, the addresses are always the same.

## The scripts

All scripts are in `contracts/` and run with `pnpm run <name>`.

| Script       | What it does                                                                                                                     |
|--------------|----------------------------------------------------------------------------------------------------------------------------------|
| `generate`   | Prints the pre-signed proxy transaction for a chain ID, with the signer and the proxy address. Nothing is sent.                  |
| `transfer`   | Sends 10 ETH from the sender account to the signer of the proxy transaction, so it can pay for the deployment.                   |
| `deploy`     | Deploys the proxy. If the proxy is already there, it does nothing. It checks the balance before and the deployed code after.     |
| `entrypoint` | Deploys the EntryPoint v0.7 through the proxy. If the code is already there, it does nothing. It checks the deployed code after. |

`transfer` runs every time, even if the proxy already exists.

## What `make contracts` does

1. Opens a port-forward to the sequencer on `localhost:8545` and waits for the port.
2. Installs the dependencies with a frozen lockfile.
3. Runs `transfer`, `deploy` and `entrypoint`.
4. Closes the port-forward.

It needs the sequencer running, plus `pnpm` and `nc`. The values come from the root `.env`: see [Configuration](configuration.md#root-env).

## Using the addresses

- The deployer address and the proxy address are in the root `.env` (`RECEIVER_ADDRESS`, `CREATE2_FACTORY_ADDRESS`).
- The EntryPoint address is printed by `entrypoint`. The bundler reads it from `k8s/overlays/dev/bundler/configmap.yaml`: it must be the same address.

If you change the chain ID, the salt or the version of the EntryPoint package, run the scripts again and update all of the above. Restart the bundler after changing its ConfigMap:
`kubectl --context xai-kube -n xainet rollout restart deployment/op-bundler`.

## License of the EntryPoint

The EntryPoint bytecode comes from the npm package `@account-abstraction/contracts`. The script `entrypoint` reads the ABI and the bytecode from the JSON artifact of the package at run time. The
package is declared in `contracts/package.json` and pinned by `contracts/pnpm-lock.yaml`. It is downloaded by `pnpm install` and is **not** part of this repository.

The license information of the package is not uniform: `package.json` declares MIT, while the source file `core/EntryPoint.sol` carries the header `GPL-3.0`, and the package has no license file. Check
the terms yourself before redistributing it. If you ever copy the bytecode or the sources into a repository, keep the license notice together with them.
