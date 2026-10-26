console "stop l2"

init_bc

if is_cluster_running; then
    kubectl --context $context \
        delete \
        -k $k8s_dir \
        --ignore-not-found=true
fi