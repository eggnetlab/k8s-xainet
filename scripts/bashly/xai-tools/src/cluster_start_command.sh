init_cluster

if [ ! "$(docker ps -q -f name=$context)" ]; then
    memory=${args['--memory']}
    cpus=${args['--cpus']}

    info "starting $context"

    minikube start \
        --profile $context \
        --driver=docker \
        --container-runtime=cri-o \
        --kubernetes-version=$K8S_VERSION \
        --network=${network_name} \
        --static-ip=${network_subnet}.247 \
        --addons="ingress,ingress-dns,registry" \
        --memory $memory \
        --disk-size 50g \
        --cpus $cpus \
        --mount-string="$minikube_conf_dir/conf:/mnt/config"

    minikube -p $context ssh -- sudo ln -sf /mnt/config/registries.conf /etc/containers/registries.conf.d/zz-custom.conf
    minikube -p $context ssh -- sudo ln -sf /mnt/config/crio.conf /etc/crio/crio.conf.d/zz-custom.conf
    minikube -p $context ssh -- sudo systemctl restart crio

    minikube -p $context ssh -- sudo sysctl -w net.ipv4.conf.all.route_localnet=1
    minikube -p $context ssh -- "sudo nft 'add table ip localhost-masq; add chain ip localhost-masq postrouting { type nat hook postrouting priority srcnat; policy accept; }; add rule ip localhost-masq postrouting ip saddr 127.0.0.1 ip daddr != 127.0.0.0/8 masquerade'"

    kubectl --context $context -n kube-system wait --for=condition=Ready node --all --timeout=120s

    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
    kubectl -n kube-system patch deployment metrics-server --type=json \
      -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi

success "$context has started on address $(minikube -p $context ip)"
