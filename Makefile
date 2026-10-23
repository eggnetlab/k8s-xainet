# k8s-xainet - entry point for the local devnet.
# Keep this file thin: real logic lives in scripts/. Every target must be idempotent.

WORKDIR       := $(dir $(lastword $(MAKEFILE_LIST)))
SHELL         := bash
.SHELLFLAGS   := -euo pipefail -c
.DEFAULT_GOAL := help
.NOTPARALLEL:

# Settings come from .env (copy .env.example) or from the command line.
# .env must use plain KEY=value lines, no quotes and no spaces.
-include $(WORKDIR).env
export

OVERLAY        ?= dev
NS             ?= xainet
CONTEXT        ?= xai-kube

K8S  := $(WORKDIR)k8s/overlays/$(OVERLAY)

BC_PRE_INIT       ?=
BC_POST_INIT      ?=
BC_PRE_DOWN       ?=
BC_POST_DOWN      ?=
BC_PRE_SETUP      ?= @$(WORKDIR)scripts/xai-tools data stop -c && $(WORKDIR)scripts/xai-tools data start
BC_POST_SETUP     ?=

CLUSTER_PRE_UP    ?=
CLUSTER_POST_UP   ?=
CLUSTER_PRE_DOWN  ?=
CLUSTER_POST_DOWN ?=

.PHONY: help env up down bc-up bc-down bc-restore network cluster-up cluster-down images bc-init bc-start check

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: env network cluster-up images bc-up ## Start the whole devnet

down: bc-down cluster-down ## Stop cluster, blockchain (clean all data)

env: ## Copy every .env.example to .env in its own directory (existing .env are kept)
	@find $(WORKDIR) -name node_modules -prune -o -name .env.example -type f -print | while read -r f; do cp -n "$$f" "$${f%.example}"; done

network: ## Create the dev docker network
	@$(WORKDIR)scripts/xai-tools network

cluster-up: ## Start minikube
	$(CLUSTER_PRE_UP)
	@$(WORKDIR)scripts/xai-tools cluster start -c $(CPUS) -m $(MEMORY)
	$(CLUSTER_POST_UP)

cluster-down: ## Stop minikube
	$(CLUSTER_PRE_DOWN)
	@$(WORKDIR)scripts/xai-tools cluster stop
	$(CLUSTER_POST_DOWN)

images: ## Build xai-conf and push it to the minikube registry
	@$(WORKDIR)scripts/build-and-push.sh $(L2_CHAIN_ID) $(CONTEXT)

bc-init: ## Start l1 and init l2 blockchains
	$(BC_PRE_INIT)
	@$(WORKDIR)scripts/xai-tools l1 start
	@$(WORKDIR)scripts/xai-tools l2 init
	$(BC_POST_INIT)

bc-start: ## Start l2, deploy deterministic proxy and EntryPoint, run the bundler
	$(BC_PRE_SETUP)
	@$(WORKDIR)scripts/xai-tools l2 start
	@$(WORKDIR)scripts/deploy-contracts.sh $(L2_CHAIN_ID) $(L2_CHAIN_NAME) $(SEQUENCER_URL) $(SENDER_PRIVATE_KEY) $(RECEIVER_ADDRESS) $(ADMIN_PRIVATE_KEY) $(CREATE2_FACTORY_ADDRESS) $(SMART_CONTRACT_SALT) $(CONTEXT)
	@$(WORKDIR)scripts/xai-tools l2 bundler --start
	$(BC_POST_SETUP)

bc-down: ## Stop the blockchain
	$(BC_PRE_DOWN)
	@$(WORKDIR)scripts/xai-tools l2 stop
	@$(WORKDIR)scripts/xai-tools l1 stop
	$(BC_POST_DOWN)

bc-up: bc-init bc-start ## start the blockchain

bc-restore: bc-down bc-up ## Restore the blockchain

check: ## Render the manifests and validate them (used by CI)
	@kubectl kustomize $(K8S) | docker run -i --rm ghcr.io/yannh/kubeconform:v0.8.0 -strict -ignore-missing-schemas -summary
