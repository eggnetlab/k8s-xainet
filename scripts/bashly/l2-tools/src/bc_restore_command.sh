source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"

$source_dir/l2-tools bc stop -o
$source_dir/l2-tools bc start -o
