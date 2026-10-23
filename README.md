# k8s-xainet

A local OP Stack L2 devnet on Kubernetes (minikube), with block explorer, indexer and ERC-4337 bundler.

Clone the repository, run `make up`, and get a working L2 with the usual tools around it. The goal is to save you the weeks of work it takes to wire these pieces together.

Xainet is the OP Stack L2 that [Xailour](https://xailour.net), a Community-as-a-Service platform, uses as the base of its blockchain services. This repository is extracted from Xailour's development
environment and sets up a local, ephemeral network with the same stack.

> **Scope:** ephemeral local development network. It is **not** a production setup.
> Only the `dev` overlay is provided and tested. The `k8s/base` + `k8s/overlays` layout is meant to be extended for other environments (see [Extending](docs/extending.md)).

## What you get

- An OP Stack L2: sequencer, read replica, batcher and proposer
- A dev L1 started with [Kurtosis](https://docs.kurtosis.com/) (geth + lighthouse)
- [Blockscout](https://www.blockscout.com/) block explorer
- [The Graph](https://thegraph.com/) indexer (graph-node)
- [Skandha](https://github.com/etherspot/skandha) ERC-4337 bundler, with the deterministic deployment proxy and the EntryPoint v0.7 deployed for your chain ID
- Postgres, IPFS and Redis in Docker Compose

All image tags are pinned. See [Architecture](docs/architecture.md) for versions and the network plan.

## Requirements

Linux, Docker (with Compose), minikube, kubectl, Kurtosis CLI, Node.js with pnpm, `nc` and `make`. The minikube cluster uses 4 CPUs and 8 GB of RAM by default.

The project is developed and tested on Linux. macOS and Windows are not tested. Full details: [Getting started](docs/getting-started.md).

## Quick start

```bash
git clone https://github.com/eggnetlab/k8s-xainet.git
cd k8s-xainet
make up      # start everything
make down    # stop everything (the data is reset at the next start)
```

`make help` lists all targets. Each step of `make up` can also be run on its own.

## Endpoints

| Service   | Address                                                                                       |
|-----------|-----------------------------------------------------------------------------------------------|
| Explorer  | `http://explorer.xainet.xaidev`                                                               |
| The Graph | `http://graph.xainet.xaidev`                                                                  |
| L2 RPC    | not exposed by an ingress: use `kubectl -n xainet port-forward statefulsets/op-seq 8545:8545` |
| Bundler   | service `op-bundler`, port `14337`, inside the cluster                                        |

The `*.xaidev` names must resolve to the minikube IP. See [Troubleshooting](docs/troubleshooting.md).

## Fixed values

|                      |                                      |
|----------------------|--------------------------------------|
| L2 name              | `Xainet`                             |
| L2 chain ID          | `19970727`                           |
| L1 chain ID          | `900`                                |
| Currency             | ETH, 18 decimals                     |
| Docker network       | `xai-devnet`, subnet `172.25.0.0/24` |
| minikube profile     | `xai-kube`                           |
| Kubernetes namespace | `xainet`                             |

These values are constants of this project, not settings. The chain ID, the Docker network (name, subnet and the addresses of the components), the minikube profile and the namespace are written in
more than one file, and changing one of them in a single place breaks the setup. See [Configuration](docs/configuration.md#fixed-values) for where each value is defined.

## Documentation

- [Architecture](docs/architecture.md): components, versions, network plan, startup flow
- [Getting started](docs/getting-started.md): requirements and step by step usage
- [Configuration](docs/configuration.md): the `.env` files and fixed values
- [Contracts](docs/contracts.md): deterministic proxy and EntryPoint
- [Extending](docs/extending.md): what to provide to build a `test` or `prod` overlay
- [Troubleshooting](docs/troubleshooting.md): known problems

Each of `bc-conf`, `contracts/` and `scripts/` has its own README.

## Security

All keys, passwords and secrets in this repository are **development values, published on purpose**. Never reuse them on a real network and never send real funds to these addresses.
`ADMIN_PRIVATE_KEY` is the well-known first account key of Hardhat and Anvil.

The `dev` setup exposes admin APIs inside the cluster. Do not expose it to the internet.

## License

[MIT](LICENSE). The EntryPoint bytecode comes from the npm package `@account-abstraction/contracts`, which is downloaded at install time and is not part of this repository.
See [Contracts](docs/contracts.md#license-of-the-entrypoint).

## Maintainer

[Andrea Venturoli](https://www.linkedin.com/in/andreaventuroli-architect), [EggNet Lab](https://github.com/eggnetlab).