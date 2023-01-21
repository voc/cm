#!/bin/bash

# do not alert about shutdowns for proxmox hosts
[[ -n "$(command -v pvenode)" ]] && exit 0

MY_HOSTNAME="$(hostnamectl --static)"
[[ -z "$MY_HOSTNAME" ]] && exit 1

MESSAGE="$(jq \
    --null-input \
    --arg name "$MY_HOSTNAME" \
    --compact-output \
    '{"name": $name}')"

for i in 1 2 3 ; do
    voc2mqtt \
        -t "/voc/shutdown" \
        -m "$MESSAGE" && break
done
