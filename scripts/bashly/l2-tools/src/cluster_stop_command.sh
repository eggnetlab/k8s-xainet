init_cluster

MINIKUBE_PROFILE="${args['--profile']}"

minikube -p $MINIKUBE_PROFILE ssh -- sudo nft delete table ip localhost-masq
minikube -p $MINIKUBE_PROFILE stop

if [[ "${args['--clean']}" ]]; then
  minikube -p $MINIKUBE_PROFILE delete
fi
