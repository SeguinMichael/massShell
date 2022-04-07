#!/bin/bash

function ssh_ () {
    #echo ssh_ : "$@" >&2
    ssh -o "ConnectTimeout 3" \
         -o "StrictHostKeyChecking no" \
         -o "UserKnownHostsFile /dev/null" \
         "$@" 2>/dev/null
}

function dig_ () {
    dig +short $1
}

function reboot_host () {
    conn_string="$1"
    login=$(cut -d"@" -f1 <<< "$conn_string")
    hostname=$(cut -d"@" -f2 <<< "$conn_string")
    [ -z "$hostname" ] && hostname="${login}" #conn_string was hostname only

    IP=$(host $hostname)

    if [ -n "$DEBUG" ]
    then
        CMD="uptime"
    else
        CMD="sudo reboot"
    fi
    ssh_ -q ${login}@$IP "$CMD" </dev/null &
    echo "$1 ($IP) => Commande envoyée : $CMD" >&2
}
