console "stop l2"

init_bc

kubectl delete \
    -k $k8s_dir \
    --ignore-not-found=true
