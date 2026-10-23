# bc-conf

Configuration of the two blockchains: the dev L1 and the L2 that runs on top of it.

| File                  | Purpose                                                                |
|-----------------------|------------------------------------------------------------------------|
| `network_params.yaml` | Parameters of the dev L1, started with the Kurtosis `ethereum-package` |
| `genesis-l1.json`     | Chain configuration of that L1                                         |
| `intent.toml`         | op-deployer intent: chain ID, roles and parameters of the L2           |
| `Dockerfile`          | Builds the `xai-conf` image                                            |
| `init.sh`             | Entry point of the `xai-conf` image, run by the `init-l2` job          |
| `.env.example`        | L1 name and addresses, names and ports of the L2 services              |

## The L1

`network_params.yaml` starts one execution client (geth) and one consensus client (lighthouse), with network ID `900`, 2-second slots and a persistent enclave. It also preloads the canonical
deterministic deployment proxy on the L1.

`make bc-init` starts it with `scripts/xai-tools l1 start`, which then connects the two client containers to the Docker network with the static addresses from `.env`.

## The `xai-conf` image

The image is built by `make images`, with the L2 chain ID as a build argument. It is based on op-deployer `v0.7.1` and contains `jq`.

At build time it reads the L1 chain ID from `genesis-l1.json` and runs `op-deployer init` for the L2 chain ID. It then adds `intent.toml` and `genesis-l1.json`.

At run time (`init.sh`) it receives four arguments: L1 chain ID, L1 RPC URL, L2 chain ID and the deployer private key. It then:

1. copies the network data to the work volume;
2. deploys the OP Stack contracts on the L1 (`op-deployer apply`);
3. writes `genesis.json`, `rollup.json` and `addresses.json` to the work volume;
4. writes an `.env` file with the address of the dispute game factory.

The script stops at the first error.

## Values that must stay consistent

- **L2 chain ID.** It is a build argument of the image and also appears in `intent.toml`, in hexadecimal (`id = 0x...130baa7`). Change both, and the other places listed
  in [Configuration](../docs/configuration.md#l2-chain-id).
- **`genesis-l1.json` and `network_params.yaml`.** The genesis file must describe the L1 started with these parameters. The image reads the L1 chain ID from it, and op-node uses it as the L1 chain
  configuration (`--rollup.l1-chain-config`). If you change the network ID, the forks or the preloaded contracts in `network_params.yaml`, regenerate `genesis-l1.json` and run `make images` again.
- **L1 addresses.** `L1_EL_ADDR` and `L1_CL_ADDR` in `.env` must match the L1 URLs in the ConfigMap `blockchain-config-env` of the overlay.

## Roles in `intent.toml`

`intent.toml` sets `fundDevAccounts = true` and uses development addresses for all roles. The L2 proxy admin owner is the address of the well-known first Hardhat and Anvil account. These are
development values and are public.
