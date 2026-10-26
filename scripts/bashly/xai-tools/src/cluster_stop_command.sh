init_cluster

if is_cluster_running; then
    minikube -p $context ssh -- sudo nft delete table ip localhost-masq
    minikube -p $context stop
fi

if [[ "${args['--clean']:-}" ]]; then
  minikube -p $context delete
fi
