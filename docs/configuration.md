# Configuration

## The `.env` files

Each folder that needs settings has its own `.env.example`. `make env` copies each one to `.env` in the same folder and keeps any `.env` that already exists. The `.env` files are ignored by git.

| File            | Used by                                                                                         | Content                                                                               |
|-----------------|-------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| `.env` (root)   | Makefile, which passes the values to `build-and-push.sh` and `deploy-contracts.sh` as arguments | Network and cluster names, L2 chain ID and name, RPC URL, deployer keys and addresses |
| `data/.env`     | `docker-compose.yaml`, `xai-tools data`                                                         | Names, aliases and addresses of Postgres, IPFS and Redis, and the database settings   |
| `bc-conf/.env`  | `xai-tools l1`, `xai-tools l2`                                                                  | L1 name and addresses, names and ports of the L2 services                             |
| `minikube/.env` | `xai-tools cluster`                                                                             | Kubernetes version                                                                    |

The compose file and the `xai-tools` commands read the `.env` of their own folder, so they work on their own, with or without `make`. The scripts `build-and-push.sh` and `deploy-contracts.sh` receive
their values as arguments.

### Root `.env`

| Variable                       | Meaning                                                                    |
|--------------------------------|----------------------------------------------------------------------------|
| `CPUS`, `MEMORY`               | minikube cpu and memory                                                    |
| `L2_CHAIN_ID`, `L2_CHAIN_NAME` | Chain ID and name of the L2                                                |
| `SEQUENCER_URL`                | RPC URL used by the deploy scripts (reached with a port-forward on `8545`) |
| `SENDER_PRIVATE_KEY`           | Account that funds the deployer of the proxy                               |
| `RECEIVER_ADDRESS`             | Deployer address of the proxy transaction. **Derived from the chain ID.**  |
| `ADMIN_PRIVATE_KEY`            | Account that deploys the EntryPoint                                        |
| `CREATE2_FACTORY_ADDRESS`      | Address of the deterministic proxy. **Derived from the chain ID.**         |
| `SMART_CONTRACT_SALT`          | Salt used to deploy the EntryPoint                                         |

### Other files

- **`data/.env`**: the database is `xaidb`. Each name in `PSQLDB_SCHEMAS` gets its own user and schema (today: `blockscout`). The Graph uses a separate database called `graph`. All users share
  `PSQLDB_USER_PASSWORD`.
- **`bc-conf/.env`**: `L1_NAME` is the Kurtosis enclave, `L1_EL_ADDR` and `L1_CL_ADDR` are the static addresses of the L1 clients. The other values are the names and ports used when waiting for the
  services.
- **`minikube/.env`**: `K8S_VERSION`.

## Fixed values

Some values look like settings but are constants of the project. The same value is written in several files, so changing it in one place breaks the setup.

### Network name, subnet and addresses

`xai-devnet` and the addresses `172.25.0.x` appear in:

- the root `.env` (`NETWORK_NAME`, `NETWORK_SUBNET`);
- `data/docker-compose.yaml` (external network name) and `data/.env` (addresses);
- `bc-conf/.env` (L1 addresses) and the script `l1 start` (network name);
- the Kubernetes ConfigMaps in `k8s/overlays/dev/setup/configmaps/config/` (L1 URLs, database and IPFS hosts).

See the full plan in [Architecture](architecture.md#network-plan). If the subnet conflicts with a network on your machine (VPN, other Docker networks),
see [Troubleshooting](troubleshooting.md#the-docker-network-cannot-be-created).

### L2 chain ID

`19970727` appears in:

- the root `.env` (`L2_CHAIN_ID`), which is also passed as a build argument of the `l2-conf` image;
- `bc-conf/intent.toml`, in hexadecimal (`0x...130baa7`);
- `k8s/overlays/dev/setup/configmaps/config/blockchain.yaml` (`l2ChainId`).

Three more values are **derived** from the chain ID and must be recomputed if it changes:

- `RECEIVER_ADDRESS` and `CREATE2_FACTORY_ADDRESS` in the root `.env`;
- the EntryPoint address in `k8s/overlays/dev/bundler/configmap.yaml`.

`pnpm run generate` in `contracts/` prints the proxy data for a chain ID. See [Contracts](contracts.md).

### Sequencer peer ID

`sequencerId` in the ConfigMap `p2p-config-env` is the libp2p peer ID derived from the key `priv` in the Secret `p2p-private-key`. If you change the key, change the peer ID too.

### L1 genesis

`bc-conf/genesis-l1.json` must match the L1 started by `bc-conf/network_params.yaml`. See [bc-conf/README.md](../bc-conf/README.md).

## Development keys

All keys are development values and are public. Two of them deserve a note:

- `ADMIN_PRIVATE_KEY` is the well-known first account of Hardhat and Anvil. Real funds sent to that address on a public network are usually swept by bots.
- The address of that same key is the `l2ProxyAdminOwner` in `bc-conf/intent.toml`: whoever can reach the devnet with that key controls the L2 proxy admin.
