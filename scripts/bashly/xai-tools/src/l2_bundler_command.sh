init_bc

if [[ "${args['--start']:-}" ]]; then
    console "start l2 bundler"
    kubectl --context $context apply -k $k8s_dir/bundler

    check_pod $L2_BUNDLER_NAME $L2_BUNDLER_PORT
fi

if [[ "${args['--stop']:-}" ]]; then
    console "stop l2 bundler"
    kubectl --context $context delete -k $k8s_dir/bundler
fi
