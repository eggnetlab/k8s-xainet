init_cluster

minikube -p $context ssh -- sudo nft delete table ip localhost-masq
minikube -p $context stop

if [[ "${args['--clean']:-}" ]]; then
  minikube -p $context delete
fi
