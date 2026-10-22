console "exec stop data"

init_data

ARGS=""
if [[ "${args['--clean']:-}" ]]; then
  ARGS="-v"
fi

docker compose -f $data_conf_dir/docker-compose.yaml down $ARGS
