df -h | tail -n +2 | while read line
do
    device=$(echo $line | awk '{ print $1 }')
    disk_usage_percent=$(echo $line | awk '{ print $5 }' | tr -d '%')
    disk_space=$(echo $line | awk '{ print $2 }')
    disk_space_avilable=$(echo $line | awk '{ print $4 }')
    mount_point=$(echo $line | awk '{ print $6 }')

    if [ "$disk_usage_percent" -ge 95 ]
    then
        errtype="error"
    else
        errtype="warn"
    fi

    if [ "$disk_usage_percent" -ge 90 ]
    then
        voc2alert "${errtype}" "disk" "${device}: disk usage ${disk_usage_percent}%, only ${disk_space_avilable} left of ${disk_space} (mounted on ${mount_point})"
    fi
done
