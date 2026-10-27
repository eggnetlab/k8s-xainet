console "init l2"

init_bc

kubectl="kubectl --context $context -n $namespace"

$kubectl apply -k $k8s_dir/setup
$kubectl apply -f $k8s_dir/init/init-l2.yaml
$kubectl wait --for=condition=complete job/init-l2 --timeout=300s

$kubectl apply -f $k8s_dir/init/init-seq.yaml
$kubectl apply -f $k8s_dir/init/init-rep.yaml
$kubectl wait --for=condition=complete job/init-seq --timeout=300s
$kubectl wait --for=condition=complete job/init-rep --timeout=300s
