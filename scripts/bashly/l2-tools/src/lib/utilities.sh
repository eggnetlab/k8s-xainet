init_l1() {
    source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
    l1_conf_dir=$source_dir/../l1-conf

    set -e
    set -a
    source $l1_conf_dir/.env
    set +a
}

init_l2() {
    source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
    l2_conf_dir=$source_dir/../l2-conf

    k8s_dir=$source_dir/../k8s/overlays/dev

    set -e
    set -a
    source $l2_conf_dir/.env
    set +a
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

init_cluster() {
    source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
    minikube_conf_dir=$source_dir/../minikube

    set -a
    source $minikube_conf_dir/.env
    set +a
}
