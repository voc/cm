OLDIFS=$IFS
IFS=$'\n'

for line in $(zfs list -d1 -Ho name,used | sort -k1 -h)
do
    voc2alert "info" "zfs/usage" "$line"
done

IFS=$OLDIFS
