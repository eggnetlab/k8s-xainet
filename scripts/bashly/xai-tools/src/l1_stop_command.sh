console "stop l1"

init_bc

if [[ -n "$(kurtosis enclave ls --cli-log-level warning | grep $L1_NAME)" ]]; then
    kurtosis enclave rm -f $L1_NAME
fi