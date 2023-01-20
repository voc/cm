OLDIFS=$IFS
IFS=$'\n'

if [[ "$(date '+%H%M')" == "1337" ]]
then
    for line in $(zfs list -d1 -Ho name,used | sort -k1 -h)
    do
        voc2alert "info" "zfs/usage" "$line"
    done
fi

IFS=$OLDIFS
