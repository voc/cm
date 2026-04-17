apt-get update
exitcode="$?"

if (( "$exitcode" > 0 ))
then
    voc2alert "error" "apt" "Daily 'apt-get update' failed with exitcode $exitcode"
fi

if (( "$(cut -d. -f1 /proc/uptime)" > 604800 ))
then
    updateable="$(apt list --upgradable 2>/dev/null | awk '/\// {print $1}' | wc -l)"

    if (( "$updateable" > 0 ))
    then
        voc2alert "warn" "apt" "$updateable packages can be upgraded. Run 'apt list --upgradable' to get a list, or 'do-unattended-upgrades' to install them"
    fi
fi
