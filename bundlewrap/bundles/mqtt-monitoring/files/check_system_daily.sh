#!/bin/bash


[[ -n "$DEBUG" ]] && set -x

for file in /usr/local/sbin/check_system_daily.d/*.sh
do
    if [ -x "${file}" ]; then
        . "${file}"
    fi
done

# we must 'exit 0' here, otherwise the exit status of voc2alert (or whatever
# else was last executed) is used to determine the exit status of this script
exit 0
