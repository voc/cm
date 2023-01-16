#!/bin/bash

MESSAGE="$(jq \
    --null-input \
    --arg name "$(hostnamectl --static)" \
    --compact-output \
    '{"name": $name}')"

for i in 1 2 3 ; do
    voc2mqtt \
        -t "/voc/shutdown" \
        -m "$MESSAGE" && break
done
