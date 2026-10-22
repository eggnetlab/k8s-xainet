init_bc() {
    source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
    bc_conf_dir=$source_dir/../bc-conf
    k8s_dir=$source_dir/../k8s/overlays/dev

    set -e
    set -a
    source $bc_conf_dir/.env
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
