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

PROFILE  ?= xainet-dev
REGISTRY ?= localhost:5000
OVERLAY  ?= dev
NS       ?= xainet

K8S  := k8s/overlays/$(OVERLAY)
KCTL := kubectl --context $(PROFILE)

.PHONY: help up down network compose cluster images setup init apply contracts check status logs

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: network compose cluster images setup init apply contracts ## Start the whole devnet

down: ## Remove cluster, containers and network
	scripts/down.sh

network: ## Create the dev docker network
	scripts/l2-tools network $(NETWORK_NAME) -a $(NETWORK_BASE_ADDRESS)

compose: ## Start Postgres, IPFS and Redis
	docker compose -f compose/compose.yaml up -d --wait

cluster: ## Start minikube
	scripts/minikube/start.sh

images: ## Build l2-conf and push it to the minikube registry
	scripts/push-images.sh

setup: ## Apply namespace, service account, config and PVCs
	$(KCTL) apply -k $(K8S)/setup

init: ## Generate the L2 config and deploy the L1 contracts
	$(KCTL) apply -k $(K8S)/init
	$(KCTL) -n $(NS) wait --for=condition=complete job/init-l2 --timeout=15m

apply: ## Apply the rest of the overlay
	$(KCTL) apply -k $(K8S)

contracts: ## Deploy deterministic proxy and EntryPoint, update the bundler
	cd deploy && npm ci && npm run deploy
	scripts/update-bundler.sh

check: ## Render the manifests and validate them (used by CI)
	kubectl kustomize $(K8S) | kubeconform -strict -ignore-missing-schemas -summary

status: ## Show pods, volumes and ingresses
	$(KCTL) -n $(NS) get pods,pvc,ingress

logs: ## Follow logs: make logs POD=op-seq-0
	@test -n "$(POD)" || { echo "usage: make logs POD=<pod name>"; exit 1; }
	$(KCTL) -n $(NS) logs -f $(POD) --all-containers
