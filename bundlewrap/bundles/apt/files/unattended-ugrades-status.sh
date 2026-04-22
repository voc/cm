if [[ -f "/var/lib/unattended_upgrades.status" ]]
then
    exitcode="$(cat "/var/lib/unattended_upgrades.status")"

    if (( "$exitcode" > 0 ))
    then
        voc2alert "warn" "apt" "unattended-upgrades failed with exit code $exitcode"
    fi
fi
