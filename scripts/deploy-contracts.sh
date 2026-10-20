#!/bin/bash

source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"

L2_CHAIN_ID=$1
L2_CHAIN_NAME=$2
SEQUENCER_URL=$3
SENDER_PRIVATE_KEY=$4
RECEIVER_ADDRESS=$5
ADMIN_PRIVATE_KEY=$6
CREATE2_FACTORY_ADDRESS=$7
SMART_CONTRACT_SALT=$8

NS="xainet"
TARGET="statefulsets/op-seq"
PORT=8545
LOG="$(mktemp)"

kubectl -n "$NS" port-forward "$TARGET" "${PORT}:${PORT}" >"$LOG" 2>&1 &
PF_PID=$!

cleanup() {
  kill "$PF_PID" 2>/dev/null || true
  wait "$PF_PID" 2>/dev/null || true
  rm -f "$LOG"
}

trap cleanup EXIT

until nc -z 127.0.0.1 8545; do
  kill -0 $PF_PID
  sleep 1
done

pnpm="pnpm --dir ${source_dir}/../contracts"

$pnpm install --frozen-lockfile
$pnpm run transfer --chain-id ${L2_CHAIN_ID} --chain-name ${L2_CHAIN_NAME} --rpc-url ${SEQUENCER_URL} --sender-key ${SENDER_PRIVATE_KEY} --receiver-address ${RECEIVER_ADDRESS}
$pnpm run deploy --chain-id ${L2_CHAIN_ID} --rpc-url ${SEQUENCER_URL}
$pnpm run entrypoint --chain-id ${L2_CHAIN_ID} --chain-name ${L2_CHAIN_NAME} --rpc-url ${SEQUENCER_URL} --private-key ${ADMIN_PRIVATE_KEY} --factory-address ${CREATE2_FACTORY_ADDRESS} --salt ${SMART_CONTRACT_SALT}
