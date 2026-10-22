console "start l2"

init_bc

kubectl --context $context apply -k $k8s_dir/sequencer

check_pod $L2_SEQ_NAME $L2_SEQ_PORT_GETH
check_pod $L2_SEQ_NAME $L2_SEQ_PORT_NODE

kubectl --context $context apply -k $k8s_dir/services

check_pod $L2_REP_NAME $L2_REP_PORT_GETH
check_pod $L2_REP_NAME $L2_REP_PORT_NODE
check_pod $L2_GRAPH_NAME $L2_GRAPH_PORT

kubectl --context $context apply -k $k8s_dir/explorer
