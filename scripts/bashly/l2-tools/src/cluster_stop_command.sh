init_cluster

minikube stop -p $MINIKUBE_PROFILE

if [[ "${args['--clean']}" ]]; then
  minikube delete -p $MINIKUBE_PROFILE
fi
