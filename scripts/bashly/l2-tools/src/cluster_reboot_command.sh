source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"

$source_dir/l2-tools cluster stop
$source_dir/l2-tools cluster start
