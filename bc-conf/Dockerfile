FROM us-docker.pkg.dev/oplabs-tools-artifacts/images/op-deployer:v0.7.1

RUN apk update && \
    apk add --no-cache \
    jq

# ARG L1_CHAIN_ID
ARG L2_CHAIN_ID

WORKDIR /network-data

COPY ./genesis-l1.json /tmp/genesis-l1.json

RUN op-deployer init \
    --l1-chain-id "$(jq -r '.config.chainId' /tmp/genesis-l1.json)" \
    --l2-chain-ids "${L2_CHAIN_ID}" \
    --workdir /network-data \
    --intent-type custom

COPY ./intent.toml /network-data/intent.toml
COPY ./genesis-l1.json /network-data/genesis-l1.json
COPY ./init.sh /usr/local/bin

ENTRYPOINT ["init.sh"]
