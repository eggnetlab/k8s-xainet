console "init l2"

init_bc

kubectl --context $context apply -k $k8s_dir/setup
kubectl --context $context apply -f $k8s_dir/init/init-l2.yaml
kubectl --context $context wait --for=condition=complete job/init-l2 -n $namespace --timeout=300s

kubectl --context $context apply -f $k8s_dir/init/init-seq.yaml
kubectl --context $context apply -f $k8s_dir/init/init-rep.yaml
kubectl --context $context wait --for=condition=complete job/init-seq -n $namespace --timeout=300s
kubectl --context $context wait --for=condition=complete job/init-rep -n $namespace --timeout=300s
