#!/bin/bash


[[ -n "$DEBUG" ]] && set -x

for file in /usr/local/sbin/check_system_daily.d/*.sh
do
    if [ -x "${file}" ]; then
        . "${file}"
    fi
done
