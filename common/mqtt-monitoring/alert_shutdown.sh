#!/bin/bash

if [[ -z "$MY_HOSTNAME" ]]
then
    MY_HOSTNAME="$(hostnamectl --static)"
fi

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
