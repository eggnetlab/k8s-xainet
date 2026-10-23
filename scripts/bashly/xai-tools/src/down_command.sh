source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"

set +e

$source_dir/l2-tools bc stop
$source_dir/l2-tools cluster stop
$source_dir/l2-tools data stop -c
