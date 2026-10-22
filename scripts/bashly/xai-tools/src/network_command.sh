
if [ "$(docker network ls -q -f name=^${network_name}$)" ]; then
    info "network '$network_name' already exists"
else
    docker network create "$network_name" \
        --opt com.docker.network.driver.mtu=1400 \
        --gateway=${network_subnet}.1 \
        --subnet=${network_subnet}.0/24 \
        --ip-range=${network_subnet}.0/25 \
        --opt com.docker.network.bridge.name="br_${network_name}"
    success "network '$network_name' created"
fi
