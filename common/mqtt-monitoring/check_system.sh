#!/bin/bash


[[ -n "$DEBUG" ]] && set -x

if [[ -z "$MY_HOSTNAME" ]]
then
    MY_HOSTNAME="$(hostnamectl --static)"
fi

PER_HOST_TOPIC="$(echo -n "hosts/$MY_HOSTNAME" | sed 's/\.c3voc\.de$//g')"
KERNEL_LOG=$(journalctl _TRANSPORT=kernel --since "10 minutes ago" --no-pager --no-hostname -o short-full -a)
PING_MESSAGE="$(jq \
    --null-input \
    --arg ips "$(ip -brief a | awk '{if ($2 == "UP") {for(i=3;i<=NF;++i)print $i}}' | tr '\n' ' ')" \
    --arg uptime "$(cat /proc/uptime | awk '{ print $1 }')" \
    --arg hostname "$MY_HOSTNAME" \
    --compact-output \
    '{"name": $hostname, "interval": 60, "additional_data": {"uptime": $uptime, "ips": $ips}}')"

# only check in if hostname is set and this is not a proxmox node
if [[ -n "$MY_HOSTNAME" ]] && [[ -z "$(command -v pvenode)" ]]
then
    for i in 1 2 3 ; do
        voc2mqtt \
            -t "/voc/checkin" \
            -m "$PING_MESSAGE" && break
    done

    for i in 1 2 3 ; do
        voc2mqtt \
            -t "$PER_HOST_TOPIC/checkin" \
            -m "$PING_MESSAGE" && break
    done
fi

for file in /usr/local/sbin/check_system.d/*.sh
do
    if [ -x "${file}" ]; then
        . "${file}"
    fi
done
