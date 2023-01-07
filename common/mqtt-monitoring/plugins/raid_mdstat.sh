if [ -r "/proc/mdstat" ]
then
    cat /proc/mdstat | awk '/^md/ {printf "%s: ", $1}; /blocks/ {print $NF}' | while read line; do
        raid_device=$(echo $line | cut -d ":" -f 1)
        raid_device_state=$(echo $line | cut -d " " -f 2)

        echo $raid_device_state | grep -q "_"
        if [ "0" -eq "$?" ]; then
            voc2alert "error" "raid/${raid_device}" "RAID disk failed: ${raid_device_state}"
        fi
    done
fi
