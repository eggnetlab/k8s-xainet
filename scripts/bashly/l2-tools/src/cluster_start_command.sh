init_cluster

if [ ! "$(docker ps -q -f name=ek-kube)" ]; then
    memory=${args['--memory']}
    cpus=${args['--cpus']}

    info "starting $MINIKUBE_PROFILE"

    minikube start \
        --profile $MINIKUBE_PROFILE \
        --driver=docker \
        --container-runtime=cri-o \
        --kubernetes-version=$K8S_VERSION \
        --network=$MINIKUBE_NETWORK_NAME \
        --static-ip=$MINIKUBE_NETWORK_IP \
        --addons="ingress","ingress-dns","registry" \
        --memory $memory \
        --disk-size 50g \
        --cpus $cpus \
        --mount-string="$minikube_conf_dir/conf:/mnt/config"

    minikube profile $MINIKUBE_PROFILE

    minikube ssh -- sudo ln -sf /mnt/config/registries.conf /etc/containers/registries.conf
    minikube ssh -- sudo ln -sf /mnt/config/crio.conf /etc/crio/crio.conf.d/99-custom.conf
    minikube ssh -- sudo systemctl restart crio

    kubectl -n kube-system wait --for=condition=Ready node --all --timeout=120s
fi

success "$MINIKUBE_PROFILE has started on address $(minikube -p $MINIKUBE_PROFILE ip)"
