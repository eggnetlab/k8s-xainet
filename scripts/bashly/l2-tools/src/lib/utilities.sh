init_l1() {
    source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"
    l1_conf_dir=$source_dir/../l1-conf

    set -e
    set -a
    source $l1_conf_dir/.env
    set +a
}
