console "start data"

init_data

docker compose -f $data_conf_dir/docker-compose.yaml up -d
check_serv $PSQL_ADDRESS $PSQLDB_PORT $PSQL_ALIAS
check_serv $REDIS_ADDRESS $REDIS_PORT $REDIS_ALIAS
check_serv $IPFS_ADDRESS $IPFS_PORT $IPFS_ALIAS
