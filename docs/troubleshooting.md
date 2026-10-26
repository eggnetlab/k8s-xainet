# Troubleshooting

## The `.xaidev` names do not resolve

**Symptom:** `explorer.xainet.xaidev` or `graph.xainet.xaidev` does not open.

The names must resolve to the minikube node address, which is `172.25.0.247` on this network. Two options:

- Add one line to `/etc/hosts` with that address and the two names.
- Configure your resolver to send the `xaidev` domain to the minikube ingress-dns addon. The steps depend on the system: see
  the [ingress-dns documentation](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/).

The first option is the simplest. Then check that the ingress controller is running with `make status`.

## The Docker network cannot be created

**Symptom:** `make network` fails with an error about an address pool that overlaps, or you lose connectivity to another network (VPN, other Docker networks) after starting the project.

The network uses `172.25.0.0/24`. If it conflicts with a network on your machine, remove the conflicting network if you can. Changing the subnet is possible but not supported by one setting: the
addresses are written in several files. See [Configuration](configuration.md#fixed-values) for the list.

## `make up` stops at `contracts`

**Symptom:** `make contracts` waits forever or fails before the deploy.

- `nc` or `pnpm` is not installed.
- Port `8545` is already used on your machine: the port-forward to the sequencer cannot start.
- The sequencer is not running: check with `make status`.

## `init-l2` fails

Read the logs of the job:

```bash
kubectl --context xai-kube -n xainet logs job/init-l2
```

The job is removed five minutes after it finishes, together with its logs. Typical causes:

- the L1 is not reachable at `172.25.0.129:8545`;
- the deployer account has no funds on the L1;
- the `xai-conf` image is missing (see below).

## The `xai-conf` image is not found

`init-l2` uses the short name `xai-conf:dev`. It resolves because `make cluster-up` installs a CRI-O configuration in minikube that searches `localhost:5000` first. For it to work:

- start the cluster with `make cluster-up`, not with a plain `minikube start`;
- run `make images` after the cluster is up. It needs port `5000` free on your machine for the port-forward to the registry.

## The services start slowly or restart

The cluster uses 4 CPUs and 8 GB of RAM by default. If pods are `Pending` or restart with `OOMKilled`, start the cluster with more resources
(see [Getting started](getting-started.md#run-the-steps-one-by-one)).

## Start again from zero

```bash
make down
scripts/xai-tools cluster stop --clean
make up
```

`make down` does not delete the minikube cluster. The second command does.

`make up` and `make bc-up` are not safe to run twice: if the L1 already exists, stop it first with `scripts/xai-tools l1 stop`, or run `make bc-down`. If a previous run left an L1 behind, list the
Kurtosis enclaves
with
`kurtosis enclave ls` and remove the leftover one.

## Postgres, IPFS or Redis do not start

Check the containers with `docker ps` and the logs with `docker logs <container>`. The container names are `xai-psqldb`, `xai-ipfs` and `xai-redis`. A data volume left from an older run can cause
problems: `docker volume rm <volume>` removes the volumes.
