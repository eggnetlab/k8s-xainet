#!/bin/sh

L1_CHAIN_ID=$1
L1_RPC_URL=$2
L2_CHAIN_ID=$3
DEPLOYER_PRIVATE_KEY=$4

echo "($L1_CHAIN_ID) ($L1_RPC_URL) ($L2_CHAIN_ID) ($DEPLOYER_PRIVATE_KEY)"

cp /network-data/* /workdir

op-deployer apply \
    --l1-rpc-url ${L1_RPC_URL} \
    --private-key ${DEPLOYER_PRIVATE_KEY} \
    --workdir /workdir

op-deployer inspect genesis \
    --workdir /workdir \
    --outfile /workdir/genesis.json \
    ${L2_CHAIN_ID}

op-deployer inspect rollup \
    --workdir /workdir \
    --outfile /workdir/rollup.json \
    ${L2_CHAIN_ID}

op-deployer inspect l1 \
    --workdir /workdir \
    --outfile /workdir/addresses.json \
    ${L2_CHAIN_ID}

ADDR=$(jq -r '.DisputeGameFactoryProxy // empty' /workdir/addresses.json)
echo "GAME_FACTORY_ADDRESS=$(jq -r '.DisputeGameFactoryProxy // empty' /workdir/addresses.json)" > /workdir/.env
