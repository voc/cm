OLDIFS=$IFS
IFS=$'\n'

# if /video/fuse is a mountpoint, we probably have mounted another
# storage system. Do not alert people about storage usage on that
# system.
if [[ -z "$(findmnt /video/fuse)" ]]
then
    for line in $(du -hd1 /vido | sort -hr)
    do
        if [[ "$(echo "$line" | awk '{print $1}')" != "0" ]]
        then
            voc2alert "info" "disk" "$line"
        fi
    done
fi

IFS=$OLDIFS
