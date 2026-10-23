: ${SLEEP_LENGTH:=1}

check_serv() {
    ADDR=$1
    PORT=$2
    ALIAS=$3

    while ! nc -z $ADDR $PORT; do
        info "sleeping $ALIAS"
        sleep $SLEEP_LENGTH
    done

    success "$ALIAS on"
}

check_pod() {
    NAME=$1
    PORT=$2
    FQDN="${NAME}.${namespace}.svc.cluster.local"

    kubectl="kubectl --context $context -n $namespace"

    $kubectl run test-conn -q --image=busybox:1.36 --restart=Never -- sleep 300 >/dev/null 2>&1
    $kubectl wait --for=condition=Ready pod/test-conn --timeout=10s >/dev/null 2>&1

    while ! $kubectl exec test-conn -- nc -z "$FQDN" "$PORT" >/dev/null 2>&1; do
        info "sleeping $NAME"
        sleep "$SLEEP_LENGTH"
    done

    $kubectl delete pod test-conn --now >/dev/null 2>&1
    success "$NAME on"
}
