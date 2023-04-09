OLDIFS=$IFS
IFS=$'\n'

# if /video/fuse is a mountpoint, we probably have mounted another
# storage system. Do not alert people about storage usage on that
# system.
if [[ -z "$(findmnt /video/fuse)" ]]
then
    for line in $(du -bd2 /video | sort -nr)
    do
        diskspace="$(echo "$line" | awk '{print $1}')"
        path="$(echo "$line" | awk '{print $2}')"

        # only alert if there is more than 1GB used
        if [[ "$diskspace" -gt 1073741824 ]]
        then
            voc2alert "info" "disk" "$(printf '%5s %s' "$(echo "$diskspace / 1073741824" | bc)G" "$path")"
        fi
    done
fi

IFS=$OLDIFS
