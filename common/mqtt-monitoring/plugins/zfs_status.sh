OLDIFS=$IFS
IFS=$'\n'

for line in $(zpool list -Ho name,health)
do
    name="$(echo "$line" | cut -f1)"
    health="$(echo "$line" | cut -f2)"

    if [[ "$health" != "ONLINE" ]]
    then
        voc2alert "error" "zfs/$name" "pool health reports as $health, please check using 'zpool status -v $name'"
    fi
done

for line in $(zfs list -Ho name,mounted,mountpoint)
do
    name="$(echo "$line" | cut -f1)"
    mounted="$(echo "$line" | cut -f2)"
    mountpoint="$(echo "$line" | cut -f3)"

    if [[ "$mountpoint" != "none" ]] && [[ "$mountpoint" != "-" ]] && [[ "$mounted" != "yes" ]]
    then
        voc2alert "error" "zfs/$name" "mountpoint set, but dataset is not mounted to $mountpoint"
    fi
done

IFS=$OLDIFS
