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
    NAMESPACE=${3:-xainet}
    FQDN="${NAME}.${NAMESPACE}.svc.cluster.local"

    kubectl -n xainet run test-conn -q --image=busybox:1.36 --restart=Never -- sleep 300 >/dev/null 2>&1
    kubectl -n xainet wait --for=condition=Ready pod/test-conn --timeout=10s >/dev/null 2>&1

    while ! kubectl -n xainet exec test-conn -- nc -z "$FQDN" "$PORT" >/dev/null 2>&1; do
        info "sleeping $NAME"
        sleep "$SLEEP_LENGTH"
    done

    kubectl -n xainet delete pod test-conn --now >/dev/null 2>&1
    success "$NAME on"
}
