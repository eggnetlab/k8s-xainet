# scripts

Scripts that start, stop and configure the devnet. The entry point for users is the `../Makefile` in the root of the repository. This folder is for people who want to run a single step or change the
tooling.

## `xai-tools`

`xai-tools` is a command line tool generated with [Bashly](https://bashly.dev/). The generated file is committed, so you do not need Bashly to use it.

| Command                              | What it does                                                                       |
|--------------------------------------|------------------------------------------------------------------------------------|
| `network`                            | Creates the Docker network if it does not exist                                    |
| `data start` / `data stop [--clean]` | Starts or stops Postgres, IPFS and Redis. `--clean` also removes the volumes       |
| `cluster start [--cpus] [--memory]`  | Starts minikube on the Docker network (defaults: 4 CPUs, 8g)                       |
| `cluster stop [--clean]`             | Stops minikube. `--clean` deletes the cluster                                      |
| `l1 start` / `l1 stop`               | Starts or removes the dev L1 (Kurtosis)                                            |
| `l2 init`                            | Applies the setup resources and runs the `init-l2`, `init-seq` and `init-rep` jobs |
| `l2 start` / `l2 stop`               | Starts the L2 services, or deletes all L2 resources                                |
| `l2 bundler --start` / `--stop`      | Starts or stops the bundler                                                        |

Run `scripts/xai-tools --help` for the details.

Each command reads the `.env` of its own folder (`data/`, `bc-conf/` or `minikube/`).

## Other scripts

| Script                                   | Purpose                                                                                  |
|------------------------------------------|------------------------------------------------------------------------------------------|
| `build-and-push.sh <chain id> <context>` | Builds the `l2-conf` image and pushes it to the minikube registry through a port-forward |
| `deploy-contracts.sh <9 arguments>`      | Deploys the deterministic proxy and the EntryPoint                                       |

`<context>` is the kubectl context, which is the name of the minikube profile.

`deploy-contracts.sh` takes nine positional arguments. `make contracts` passes them:

| # | Argument                  | Meaning                                      |
|---|---------------------------|----------------------------------------------|
| 1 | `L2_CHAIN_ID`             | Chain ID of the L2                           |
| 2 | `L2_CHAIN_NAME`           | Name of the L2                               |
| 3 | `SEQUENCER_URL`           | RPC URL of the sequencer                     |
| 4 | `SENDER_PRIVATE_KEY`      | Account that funds the deployer of the proxy |
| 5 | `RECEIVER_ADDRESS`        | Deployer address of the proxy transaction    |
| 6 | `ADMIN_PRIVATE_KEY`       | Account that deploys the EntryPoint          |
| 7 | `CREATE2_FACTORY_ADDRESS` | Address of the deterministic proxy           |
| 8 | `SMART_CONTRACT_SALT`     | Salt used to deploy the EntryPoint           |
| 9 | `CONTEXT`                 | kubectl context, used for the port-forward   |

## Change `xai-tools`

Do not edit the generated file. The Bashly files are in `scripts/bashly/xai-tools/`:

| Path               | Content                                                                                                |
|--------------------|--------------------------------------------------------------------------------------------------------|
| `settings.yml`     | Bashly settings. It turns strict mode on and sets two features to `development` only (see below)       |
| `generate.sh`      | Regenerates the tool in production mode                                                                |
| `src/bashly.yml`   | Definition of commands, arguments, flags and the project variables (profile, namespace, network)       |
| `src/*_command.sh` | The code of each command                                                                               |
| `src/lib/`         | Shared functions: loading the `.env` files, and waiting for services (`check_serv`, `check_pod`)       |

`settings.yml` differs from the Bashly defaults in three values:

- `strict: true`: the generated script runs in bash strict mode (`set -euo pipefail`). An unset variable or a failing command stops it. Keep this in mind when you edit the commands.
- `enable_deps_array: development` and `enable_env_var_names_array: development`: these two features are left out of the production build. With the Bashly default (`always`) they would be in the script, and the CI check on the generated script would not pass.

`generate.sh` builds in production mode (`BASHLY_ENV=production`), so everything set to `development` in `settings.yml` is left out of the generated tool.

To regenerate the tool, run `scripts/bashly/xai-tools/generate.sh`. It runs Bashly 2.0.0 in Docker and moves the generated `xai-tools` to `scripts/`.
