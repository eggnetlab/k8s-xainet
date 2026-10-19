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

init_cluster() {
    source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
    minikube_conf_dir=$source_dir/../minikube

    set -a
    source $minikube_conf_dir/.env
    set +a
}

init_data() {
    source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
    data_conf_dir=$source_dir/../data

    set -a
    source $data_conf_dir/.env
    set +a
}
