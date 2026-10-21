init_cluster

MINIKUBE_PROFILE="${args['--profile']}"

if [ ! "$(docker ps -q -f name=$MINIKUBE_PROFILE)" ]; then
    memory=${args['--memory']}
    cpus=${args['--cpus']}

    info "starting $MINIKUBE_PROFILE"

    minikube start \
        --profile $MINIKUBE_PROFILE \
        --driver=docker \
        --container-runtime=cri-o \
        --kubernetes-version=$K8S_VERSION \
        --network=${args['--network']} \
        --static-ip=${args['--ip-address']} \
        --addons="ingress","ingress-dns","registry" \
        --memory $memory \
        --disk-size 50g \
        --cpus $cpus \
        --mount-string="$minikube_conf_dir/conf:/mnt/config"

    minikube -p $MINIKUBE_PROFILE ssh -- sudo ln -sf /mnt/config/registries.conf /etc/containers/registries.conf.d/zz-custom.conf
    minikube -p $MINIKUBE_PROFILE ssh -- sudo ln -sf /mnt/config/crio.conf /etc/crio/crio.conf.d/zz-custom.conf
    minikube -p $MINIKUBE_PROFILE ssh -- sudo systemctl restart crio

    minikube -p $MINIKUBE_PROFILE ssh -- sudo sysctl -w net.ipv4.conf.all.route_localnet=1
    minikube -p $MINIKUBE_PROFILE ssh -- "sudo nft 'add table ip localhost-masq; add chain ip localhost-masq postrouting { type nat hook postrouting priority srcnat; policy accept; }; add rule ip localhost-masq postrouting ip saddr 127.0.0.1 ip daddr != 127.0.0.0/8 masquerade'"

    kubectl -n kube-system wait --for=condition=Ready node --all --timeout=120s
fi

success "$MINIKUBE_PROFILE has started on address $(minikube -p $MINIKUBE_PROFILE ip)"
