# Getting started

## Requirements

The project is developed and tested on Linux. macOS and Windows are not tested.

| Tool                                               | Used for                                                              |
|----------------------------------------------------|-----------------------------------------------------------------------|
| Docker with the Compose plugin                     | Postgres, IPFS, Redis, the L1 containers and minikube itself          |
| minikube                                           | The Kubernetes cluster (docker driver, CRI-O runtime)                 |
| kubectl                                            | Applying manifests and port-forwarding                                |
| [Kurtosis CLI](https://docs.kurtosis.com/install/) | Starting the dev L1                                                   |
| Node.js and pnpm                                   | The deploy scripts in `contracts/` (CI uses Node 22 and pnpm 10.32.1) |
| `nc` (netcat)                                      | Waiting for ports in the scripts                                      |
| `make`                                             | The entry point of the project                                        |

You do not need Bashly to run the project. The CLI `scripts/xai-tools` is already generated (see [scripts/README.md](../scripts/README.md)).

### Resources

The minikube cluster gets its CPUs and memory from the variables `CPUS` and `MEMORY`. Set them in the root `.env`, or on the command line, for example `make up CPUS=8 MEMORY=16g`. The disk is 50 GB.
The Kubernetes version is set in `minikube/.env.example` (`K8S_VERSION`).

The base manifests use the `fileKeyRef` environment source, which is recent: use the Kubernetes version tested here or a newer one.

## Start

```bash
git clone https://github.com/eggnetlab/k8s-xainet.git
cd k8s-xainet
make up
```

`make up` takes a few minutes. When it finishes, run `make status` to see pods, volumes and ingresses.

The explorer is then available at `http://explorer.xainet.xaidev`. If the name does not resolve, see [Troubleshooting](troubleshooting.md#the-xaidev-names-do-not-resolve).

## Run the steps one by one

`make up` runs `env`, `network`, `cluster-up`, `images` and `bc-up`, in this order. `bc-up` runs `bc-init` and then `bc-start`. Each of them can be run alone. Run `make help` for the list.

| Target              | What it does                                                                                                                           |
|---------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `make up`           | Starts everything.                                                                                                                     |
| `make down`         | Stops the blockchain and then the cluster (`bc-down`, `cluster-down`).                                                                 |
| `make env`          | Copies each `.env.example` to `.env` in its own folder. Existing `.env` files are kept.                                                |
| `make network`      | Creates the Docker network.                                                                                                            |
| `make cluster-up`   | Starts minikube on the Docker network.                                                                                                 |
| `make cluster-down` | Stops minikube. It does not delete the cluster.                                                                                        |
| `make images`       | Builds the `xai-conf` image and pushes it to the minikube registry.                                                                    |
| `make bc-up`        | Starts the blockchains: `bc-init`, then `bc-start`.                                                                                    |
| `make bc-init`      | Starts the L1 and initializes the L2.                                                                                                  |
| `make bc-start`     | Recreates Postgres, IPFS and Redis from scratch, starts the L2 services, deploys the proxy and the EntryPoint, and starts the bundler. |
| `make bc-down`      | Stops the L2 and the L1, then stops Postgres, IPFS and Redis and keeps their data.                                                     |
| `make bc-restore`   | Runs `bc-down` and `bc-up`. The cluster stays running.                                                                                 |
| `make contracts`    | Deploys the deterministic proxy and the EntryPoint. It needs the sequencer running. It is also part of `bc-start`.                     |
| `make status`       | Shows pods, volumes and ingresses.                                                                                                     |
| `make check`        | Renders and validates the Kubernetes manifests.                                                                                        |

The Makefile has hooks that run before and after some steps: see [Hooks](architecture.md#hooks).

## Use the L2

The L2 RPC is not exposed by an ingress. Forward the sequencer port:

```bash
kubectl -n xainet port-forward statefulsets/op-seq 8545:8545
```

The RPC is then `http://localhost:8545`, with chain ID `19970727`. The development accounts and keys are in the `.env` files and are public.

Use the EntryPoint address printed by `make contracts` in your own bundler or SDK configuration. It is not the canonical address: see [Contracts](contracts.md).

## Stop

```bash
make down
```

`make down` does the following:

- deletes the L2 resources from Kubernetes, including the volumes, so the L2 data is lost;
- removes the L1 (the Kurtosis enclave);
- stops Postgres, IPFS and Redis **without deleting their data**, so you can inspect it;
- stops the minikube cluster, **without deleting it**.

The data of Postgres, IPFS and Redis is deleted at the next start: `bc-start` recreates the three services from scratch. The Docker network is left in place.

To delete the minikube cluster as well:

```bash
scripts/xai-tools cluster stop --clean
```

## Platform notes

- **Linux:** the host reaches the addresses of the Docker network directly, so you can connect to Postgres at `172.25.0.199` without mapping ports.
- **macOS and Windows:** not tested. Docker runs inside a VM there, so the container addresses are not reachable from the host, and the registry and the ingress need extra steps.