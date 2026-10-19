source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"

# $source_dir/l2-tools l2 stop
$source_dir/l2-tools l1 stop
