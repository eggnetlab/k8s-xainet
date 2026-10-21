# k8s-xainet - entry point for the local devnet.
# Keep this file thin: real logic lives in scripts/. Every target must be idempotent.

SHELL         := bash
.SHELLFLAGS   := -euo pipefail -c
.DEFAULT_GOAL := help
.NOTPARALLEL:

# Settings come from .env (copy .env.example) or from the command line.
# .env must use plain KEY=value lines, no quotes and no spaces.
-include .env
export

OVERLAY        ?= dev
NS             ?= xainet

K8S  := k8s/overlays/$(OVERLAY)
KCTL := kubectl --context $(CONTEXT)

.PHONY: help env up down network persistance cluster images bc contracts bundler check status

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: env network persistance cluster images bc contracts bundler ## Start the whole devnet

down: ## Stop cluster, blockchain and persistance (clean all data)
	scripts/l2-tools bc stop && scripts/l2-tools cluster stop --profile $(CONTEXT) && scripts/l2-tools data stop -c

env: ## Copy every .env.example to .env in its own directory (existing .env are kept)
	find . -name node_modules -prune -o -name .env.example -type f -print | while read -r f; do cp -n "$$f" "$${f%.example}"; done

network: ## Create the dev docker network
	scripts/l2-tools network $(NETWORK_NAME) -s $(NETWORK_SUBNET)

persistance: ## Start Postgres, IPFS and Redis
	scripts/l2-tools data start

cluster: ## Start minikube
	scripts/l2-tools cluster start --profile $(CONTEXT) --network $(NETWORK_NAME) --ip-address $(NETWORK_SUBNET).247

images: ## Build l2-conf and push it to the minikube registry
	scripts/build-and-push.sh $(L2_CHAIN_ID)

bc: ## Create l1 and l2 blockchains
	scripts/l2-tools bc start

bundler: ## Run the bundler
	scripts/l2-tools l2 bundler --start

contracts: ## Deploy deterministic proxy and EntryPoint, update the bundler
	scripts/deploy-contracts.sh $(L2_CHAIN_ID) $(L2_CHAIN_NAME) $(SEQUENCER_URL) $(SENDER_PRIVATE_KEY) $(RECEIVER_ADDRESS) $(ADMIN_PRIVATE_KEY) $(CREATE2_FACTORY_ADDRESS) $(SMART_CONTRACT_SALT)

check: ## Render the manifests and validate them (used by CI)
	kubectl kustomize $(K8S) | docker run -i --rm ghcr.io/yannh/kubeconform:v0.8.0 -strict -ignore-missing-schemas -summary

status: ## Show pods, volumes and ingresses
	$(KCTL) -n $(NS) get pods,pvc,ingress
