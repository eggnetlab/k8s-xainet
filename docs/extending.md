# Extending to other environments

Only the `dev` overlay is provided and tested. The layout is meant to let you add a `test` or `prod` overlay without changing the base.

## Layout

```
k8s/
  base/                 # neutral manifests: no secrets, no environment values
    setup/ sequencer/ services/ bundler/ explorer/
  overlays/
    dev/                # everything specific to the local devnet
      setup/ sequencer/ services/ bundler/ explorer/
      init/             # one-off jobs, applied by `xai-tools l2 init`
```

The `init/` jobs are not part of the overlay `kustomization.yaml`. They are applied by hand, in order, because later steps need their result.

To create a new overlay, copy `k8s/overlays/dev`, then replace the values listed below.

## What the base expects

The base manifests refer to the objects below by name. The overlay must provide all of them.

### ConfigMaps

| Name                    | Keys                                                                                                                                                                                         |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `blockchain-config-env` | `l1ChainId`, `l1RpcUrl`, `l1BeaconUrl`, `l2ChainId`, `l2Name`, `l2RpcUrl`, `l2RollupUrl`, `l2RepUrl`, `l2RepWs`, `l2Currency`, `l2CurrencySymbol`, `l2CurrencyDecimals`, `xainet`, `testnet` |
| `psql-config-env`       | `dbHost`, `dbPort`                                                                                                                                                                           |
| `ipfs-config-env`       | `url`                                                                                                                                                                                        |
| `batcher-config-env`    | `dataAvailabilityType` (`calldata` or `blobs`)                                                                                                                                               |
| `p2p-config-env`        | `sequencerId` (libp2p peer ID of the sequencer)                                                                                                                                              |
| `blockscout-config-env` | `ECTO_USE_SSL`, `POOL_SIZE`, `POOL_SIZE_API`, `BLOCKSCOUT_HOST`, `BLOCKSCOUT_PROTOCOL`, `REDIS_URL`, `WEBSOCKET_PROTOCOL`                                                                    |
| `op-bundler-config-env` | Skandha `config.json`, including the EntryPoint address                                                                                                                                      |

The base itself defines `blockchain-config` (L2 name and currency) and `psql-config` (database names).

### Secrets

| Name              | Keys                                                   |
|-------------------|--------------------------------------------------------|
| `l2-private-key`  | `l1AdminPK`, `batcherPK`, `proposerPK`                 |
| `p2p-private-key` | `priv` (p2p identity), `sequencer` (block signing key) |
| `psql-auth`       | `password`                                             |
| `blockscout`      | `SECRET_KEY_BASE`                                      |

### Volumes and ingresses

- PVCs: `l2-workdir`, `l2-seq-data`, `l2-rep-data`.
- Ingresses for the explorer and for The Graph, in `overlays/dev/services/ingresses/`.

### Images

The overlay also provides the image of the init jobs. In `dev` it is `xai-conf:dev`, resolved through the registry configuration that `make cluster-up` installs in minikube. On another cluster, use a name
that your cluster can resolve.

## What a patch cannot fix

Moving away from `dev` is more than changing values. Plan these points on their own:

- **Keys.** In `dev` all keys are public and live in the repository. In other environments they must come from a secret manager (External Secrets, Sealed Secrets, SOPS) and never from the repository.
- **Genesis and rollup config.** In `dev` they are generated at each start. In other environments they are stable artifacts, created once and kept safe.
- **Sequencer.** There is one sequencer: no high availability.
- **Storage.** The volumes are small and the nodes run in archive mode. Choose sizes and a retention policy.
- **Admin APIs.** The `dev` setup exposes admin APIs inside the cluster and allows any CORS origin.
- **Network assumptions.** The L1, Postgres, IPFS and Redis are reached through fixed addresses on a Docker network. Another environment needs real hosts or in-cluster services.
- **Single node.** The work volume is `ReadWriteOnce` and shared by several pods.
