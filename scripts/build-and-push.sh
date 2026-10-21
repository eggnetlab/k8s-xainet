#!/bin/bash

source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
L2_CHAIN_ID=$1

set -e

docker build --build-arg L2_CHAIN_ID=$L2_CHAIN_ID -t localhost:5000/l2-conf:dev $source_dir/../bc-conf

LOG="$(mktemp)"
kubectl -n kube-system port-forward deployments/registry 5000:5000 >"$LOG" 2>&1 &
PF_PID=$!

cleanup() {
  kill "$PF_PID" 2>/dev/null || true
  wait "$PF_PID" 2>/dev/null || true
  rm -f "$LOG"
}

trap cleanup EXIT

until nc -z 127.0.0.1 5000; do
  kill -0 $PF_PID
  sleep 1
done

docker push localhost:5000/l2-conf:dev
