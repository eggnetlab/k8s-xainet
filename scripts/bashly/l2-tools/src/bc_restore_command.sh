source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"

$source_dir/l2-tools bc stop
$source_dir/l2-tools bc start
