#!/bin/sh
SILENT=0

# Display an error message and exit
panic() {
    echo -e "[\33[1;31mERR\33[0m] $@"
    echo -e "[\33[1;37mINF\33[0m] Entering rescue console"
    cat /proc/partitions
    export PS1="(initrd) "
    /bin/sh
}

# Log the beginning/end of an action
# Action description (passed to log_start) must not exceed 54 characters
_log_pad=0
log_start() {
    [ $SILENT -eq 1 ] && return
    STR="$@"
    let _log_pad=54-${#STR}
    echo -en "[\33[1;37mINF\33[0m] $@"
}
log_warn() {
    [ $SILENT -eq 1 ] && return
    echo -en "\n[\33[33mWRN\33[0m] $@"
}
log_fail() {
    [ $SILENT -eq 1 ] && return
    echo -e " \33[31mfailed\33[0m"
}
log_ok() {
    [ $SILENT -eq 1 ] && return
    SPC=$(seq $_log_pad)
    SPC=${SPC//??/ }
    echo -e " \33[32mcheck\33[0m"
}
log_info() {
    [ $SILENT -eq 1 ] && return
    SPC=$(seq $_log_pad)
    SPC=${SPC//??/ }
    echo -e " \33[32m$@\33[0m"
}

# Cluster contextualization

# Check if 'cvm_cluster_master' was set in the ucernvm section
IsOnMasterMachine() {
    local master_field=$_UCONTEXT_CVM_CLUSTER_MASTER
    if [ "x$master_field" = "xtrue" -o "x$master_field" = "xTrue" -o "x$master_field" = "x1" -o "x$master_field" = "xyes" ]; then
        return 0
    else
        return 1
    fi
}


# System initialization begins here

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
