OLDIFS=$IFS
IFS=$'\n'

for line in $(zfs list -d1 -Ho name,used | sort -k1 -h)
do
    path="$(echo "$line" | awk '{print $1}')"
    diskspace="$(zfs get -Hp used "$path" | awk '{print $3}')"

    # only alert if there is more than 1GB used
    if [[ "$diskspace" -gt 1073741824 ]]
    then
        voc2alert "info" "zfs" "$(printf '%7s %s' "$(echo "$diskspace / 1073741824" | bc)G" "$path")"
    fi
done

IFS=$OLDIFS
