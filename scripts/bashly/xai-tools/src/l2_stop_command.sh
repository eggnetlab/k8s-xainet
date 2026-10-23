console "stop l2"

init_bc

kubectl --context $context \
    delete \
    -k $k8s_dir \
    --ignore-not-found=true
