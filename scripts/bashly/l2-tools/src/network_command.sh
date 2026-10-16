network_name=${args['name']}

if [ "$(docker network ls -q -f name=^${network_name}$)" ]; then
    info "network '$network_name' already exists"
else
    base_address=${args['--base-address']}
    docker network create $network_name --gateway=$base_address.1 --subnet=$base_address.0/24 --ip-range=$base_address.0/25
    success "network '$network_name' created"
fi
