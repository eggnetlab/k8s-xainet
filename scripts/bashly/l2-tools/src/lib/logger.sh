# Logging utilities
console() { echo -e "$mark $1"; }
info() { echo -e "$(blue $mark "[INFO]" $1)"; }
success() { echo -e "$(green $mark "[SUCCESS]" $1)"; }
error() { echo -e "$(red $mark "[ERROR]" $1)"; }
