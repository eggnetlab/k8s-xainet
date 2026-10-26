: ${SLEEP_LENGTH:=1}
: ${MAX_TRIES:=120}

check_serv() {
    ADDR=$1
    PORT=$2
    ALIAS=$3

    tries=0
    while ! nc -z $ADDR $PORT; do
        tries=$((tries + 1))
        if (( tries >= MAX_TRIES )); then
            error "$ALIAS ($ADDR:$PORT) not reachable after $MAX_TRIES tries"
            return 1
        fi
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

    $kubectl delete pod test-conn --now --ignore-not-found >/dev/null
    $kubectl run test-conn -q --image=busybox:1.36 --restart=Never -- sleep 300 >/dev/null \
        || { error "cannot create the test-conn pod"; return 1; }
    $kubectl wait --for=condition=Ready pod/test-conn --timeout=120s >/dev/null \
        || { error "test-conn is not ready"; $kubectl describe pod test-conn | tail -n 15; return 1; }

    tries=0
    until $kubectl exec test-conn -- nc -z "$FQDN" "$PORT" >/dev/null 2>&1; do
        tries=$((tries + 1))
        if (( tries >= MAX_TRIES )); then
            error "$NAME:$PORT not reachable after $MAX_TRIES tries"
            $kubectl delete pod test-conn --now >/dev/null
            return 1
        fi
        info "sleeping $NAME"
        sleep "$SLEEP_LENGTH"
    done

    $kubectl delete pod test-conn --now >/dev/null

    success "$NAME on"
}

is_cluster_running() {
    [[ -n "$(docker ps -q -f name=$context)" ]];
}