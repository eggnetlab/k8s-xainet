source_dir="$(cd -- "$(dirname -- "$0")" &>/dev/null && pwd)"

$source_dir/l2-tools l1 start
$source_dir/l2-tools l2 init
$source_dir/l2-tools l2 start