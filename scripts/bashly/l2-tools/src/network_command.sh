network_name=${args['name']}

if [ "$(docker network ls -q -f name=^${network_name}$)" ]; then
    info "network '$network_name' already exists"
else
    subnet=${args['--subnet']}
    docker network create $network_name \
        --opt com.docker.network.driver.mtu=1400 \
        --gateway=${subnet}.1 \
        --subnet=${subnet}.0/24 \
        --ip-range=${subnet}.0/25
    success "network '$network_name' created"
fi
