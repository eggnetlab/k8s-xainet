source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"

$source_dir/l2-tools data start
$source_dir/l2-tools cluster start
$source_dir/l2-tools bc start
