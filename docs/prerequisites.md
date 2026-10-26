# Prerequisites

This page lists everything you need on the host before `make up`, how to check each tool, and how to install it on Linux.

The script [`scripts/install-deps.sh`](../scripts/install-deps.sh) or `make deps` installs **minikube, kubectl and Kurtosis** on Debian and Ubuntu. Everything else on this page you install yourself.

## Summary

| Tool                           | Used for                                            | Installed by the script | Check                                      |
|--------------------------------|-----------------------------------------------------|-------------------------|--------------------------------------------|
| Docker Engine + Compose plugin | Everything: minikube, the L1, Postgres, IPFS, Redis | No                      | `docker version`, `docker compose version` |
| minikube                       | The Kubernetes cluster                              | Yes                     | `minikube version`                         |
| kubectl                        | Applying manifests, port-forwarding                 | Yes                     | `kubectl version --client`                 |
| Kurtosis CLI                   | The dev L1                                          | Yes                     | `kurtosis version`                         |
| GNU `make`                     | Entry point of the project                          | No                      | `make --version`                           |
| `nc` (netcat)                  | Waiting for ports in the scripts                    | No                      | `command -v nc`                            |
| Bash 4.2 or newer              | The `xai-tools` CLI                                 | No (present on Linux)   | `bash --version`                           |
| Node.js 22 or newer            | The deploy scripts in `contracts/`                  | No                      | `node --version`                           |
| pnpm 10.32.1                   | Same                                                | No                      | `pnpm --version` (in `contracts/`)         |
| `git`, `curl`                  | Cloning the repository, downloading the tools       | No                      | `git --version`, `curl --version`          |

## The machine

| Resource | Default / needed                                                                                                                                 |
|----------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| CPUs     | 4 (`CPUS` in `.env`)                                                                                                                             |
| Memory   | 8 GB for the cluster (`MEMORY` in `.env`), plus what Docker needs for the L1 and the data services. Use more if pods restart with `OOMKilled`.   |
| Disk     | 50 GB for the minikube disk                                                                                                                      |
| Network  | Internet access to GitHub, Docker Hub, `ghcr.io` and `us-docker.pkg.dev` (images, manifests and the Kurtosis package are downloaded at run time) |
| Ports    | `5000` and `8545` free on the host: they are used by temporary port-forwards                                                                     |
| Subnet   | `172.25.0.0/24` not used by another Docker network or by a VPN                                                                                   |

## Docker

Docker is the base of everything: minikube runs as a Docker container, and Kurtosis, Postgres, IPFS and Redis run in Docker too.

### Check

Run these four commands. All of them must work **without `sudo`**:

```bash
docker version                 # shows both a Client and a Server section
docker compose version         # the Compose plugin, not the old docker-compose
docker run --rm hello-world    # pulls an image and runs a container
docker ps                      # no "permission denied" error
```

| Error                                                                   | Cause and fix                                                                |
|-------------------------------------------------------------------------|------------------------------------------------------------------------------|
| `permission denied while trying to connect to the Docker daemon socket` | Your user is not in the `docker` group. See "Use Docker without sudo" below. |
| `Cannot connect to the Docker daemon`                                   | The service is not running: `sudo systemctl enable --now docker`.            |
| `'compose' is not a docker command`                                     | The Compose plugin is missing: install the package `docker-compose-plugin`.  |

### Install on Linux

Use **Docker Engine** from Docker's own repository. Do not use Docker Desktop for Linux: it runs Docker inside a virtual machine, so the container addresses of this project (`172.25.0.x`) are not
reachable from the host. The `snap` package and rootless Docker are not tested here.

The official, up-to-date instructions for every distribution are at <https://docs.docker.com/engine/install/>. On Ubuntu the steps are:

```bash
# 1. Add Docker's repository
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2. Install Docker Engine, the CLI and the Compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Start it now and at every boot
sudo systemctl enable --now docker
```

On Debian, replace `ubuntu` with `debian` in the two URLs.

### Use Docker without sudo

```bash
sudo usermod -aG docker "$USER"
```

Then **log out and log in again** (or run `newgrp docker` in the current terminal) and repeat the check above. Members of the `docker` group have root-equivalent rights on the machine: this is normal
for a local development setup.

## minikube, kubectl and Kurtosis

On Debian and Ubuntu, run the script as your normal user. It asks for your `sudo` password once:

```bash
scripts/install-deps.sh
```

It skips what is already installed, and it installs the versions that are tested with this repository. The kubectl version should stay within one minor version of `K8S_VERSION` in
`minikube/.env.example`.

On other distributions, or if you prefer to install by hand, use the official instructions:

- minikube: <https://minikube.sigs.k8s.io/docs/start/>
- kubectl: <https://kubernetes.io/docs/tasks/tools/>
- Kurtosis: <https://docs.kurtosis.com/install/>

### Check

```bash
minikube version
kubectl version --client
kurtosis version
```

`kurtosis version` can print a warning about checking for a newer version. You can ignore it. If the engine is not started yet, the command shows only the CLI version: this is fine, `make up` starts
the engine.

## make, nc, git, curl

| Distribution   | Command                                                |
|----------------|--------------------------------------------------------|
| Debian, Ubuntu | `sudo apt-get install -y make netcat-openbsd git curl` |
| Fedora         | `sudo dnf install -y make nmap-ncat git curl`          |
| Arch           | `sudo pacman -S make openbsd-netcat git curl`          |

Check them:

```bash
make --version          # must say "GNU Make"
command -v nc           # prints a path
bash --version          # 4.2 or newer
```

## Node.js and pnpm

The scripts in `contracts/` are TypeScript. They need Node.js 22 or newer (the CI uses 22) and pnpm. The exact pnpm version, `10.32.1`, is pinned in `contracts/package.json`.

The Node.js package of many distributions is older than 22 (Ubuntu 24.04 ships version 18), so install it with [nvm](https://github.com/nvm-sh/nvm), which works without `sudo`:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash
# open a new terminal, then:
nvm install 22
```

Node.js 22 includes Corepack, which installs the pnpm version that the project asks for:

```bash
corepack enable
```

The first time you run `pnpm` inside `contracts/`, Corepack downloads version `10.32.1` (this needs internet access). If you prefer, `npm install -g pnpm@10.32.1` does the same.

### Check

```bash
node --version                     # v22.x or newer
cd contracts && pnpm --version     # 10.32.1
```

## Names of the services on your machine

The explorer and The Graph use names that end in `.xaidev`. Your computer does not know them until you tell it. The simplest way is one line in `/etc/hosts`:

```bash
echo "172.25.0.247 explorer.xainet.xaidev graph.xainet.xaidev" | sudo tee -a /etc/hosts
```

`172.25.0.247` is the fixed address of the minikube node (see [Architecture](architecture.md#network-plan)). You can add the line before the cluster exists. Other options are
in [Troubleshooting](troubleshooting.md#the-xaidev-names-do-not-resolve).

## Check everything at once

```bash
for tool in docker minikube kubectl kurtosis make nc node pnpm git curl; do
  if command -v "$tool" >/dev/null 2>&1; then echo "ok       $tool"; else echo "MISSING  $tool"; fi
done

docker compose version >/dev/null 2>&1 && echo "ok       docker compose" || echo "MISSING  docker compose"
docker info >/dev/null 2>&1            && echo "ok       docker usable"  || echo "PROBLEM  docker is not usable by this user"
```

When every line starts with `ok`, you are ready: go back to [Getting started](getting-started.md#start).
