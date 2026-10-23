console "start l1"

init_bc

kurtosis run github.com/ethpandaops/ethereum-package@6.1.0 \
    --args-file $bc_conf_dir/network_params.yaml \
    --enclave $L1_NAME

GETH_CONTAINER_NAME=$(docker ps --filter "label=kurtosis_service_name=el-1-geth-lighthouse" --format "{{.Names}}")
docker network connect \
    --ip $L1_EL_ADDR \
     xai-devnet $GETH_CONTAINER_NAME

GETH_CONTAINER_NAME=$(docker ps --filter "label=kurtosis_service_name=cl-1-lighthouse-geth" --format "{{.Names}}")
docker network connect \
    --ip $L1_CL_ADDR \
     xai-devnet $GETH_CONTAINER_NAME