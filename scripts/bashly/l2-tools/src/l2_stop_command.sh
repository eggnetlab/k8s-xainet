console "stop l2"

init_l2

kubectl delete \
    -k $k8s_dir \
    --ignore-not-found=true

#$source_dir/xai-data psqldb restore graph,blockscout
