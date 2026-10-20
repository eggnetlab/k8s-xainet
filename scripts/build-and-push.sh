#!/bin/bash

source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
L2_CHAIN_ID=$1

set -e

docker build --build-arg L2_CHAIN_ID=$L2_CHAIN_ID -t l2-conf:dev $source_dir/../l1-conf
minikube image load l2-conf:dev
