#!/bin/bash

MY_HOSTNAME="$(hostnamectl --static)"
KERNEL_LOG=$(journalctl _TRANSPORT=kernel --since "10 minutes ago" --no-pager --no-hostname -o short-full -a)

PING_MESSAGE="$(jq \
    --null-input \
    --arg ips "$(ip -brief a | awk '{if ($2 == "UP") {for(i=3;i<=NF;++i)print $i}}' | tr '\n' ' ')" \
    --arg uptime "$(cat /proc/uptime | awk '{ print $1 }')" \
    --arg hostname "$MY_HOSTNAME" \
    --compact-output \
    '{"name": $hostname, "interval": 60, "additional_data": {"uptime": $uptime, "ips": $ips}}')"

if [[ -n "$MY_HOSTNAME" ]]
then
    for i in 1 2 3 ; do
        voc2mqtt \
            -t "/voc/checkin" \
            -m "$PING_MESSAGE" && break
    done

    for i in 1 2 3 ; do
        voc2mqtt \
            -t "hosts/$(hostnamectl --static | sed 's/\.c3voc\.de$//g')/checkin" \
            -m "$PING_MESSAGE" && break
    done
fi

for file in /usr/local/sbin/check_system.d/*.sh
do
    if [ -x "${file}" ]; then
        . "${file}"
    fi
done

# I'm sorry, legacy shit follows below…

# check_raid implements:
#
#  * mdadm status of existing md devices
#  * megacli raid controller status via wrapper raidstatus
#    (available e.g. on storage and ${TRUNC_HOSTNAME})
#  * megacli battery status via wrapper raidstatus
#
check_raid () {
  if [ -e "$(command -v zpool)" ] && [ "$(lsmod | grep -q zfs; echo $?)" -eq "0" ];then
    zpool list -H -o name,health | while read line; do
      pool_name=$(echo $line| awk  '{ print $1 }')
      pool_health=$(echo $line| awk  '{ print $2 }')

      echo $pool_health | grep -iqE 'online'
      if [ "$?" -ne "0" ]; then
        send_mqtt_message "error" "system/zfs/${TRUNC_HOSTNAME}" "<red>ZFS pool '${zfs_pool}' is '${pool_health}' please run 'zpool status' for more information</red>"
      fi

      debug_output "zfs" $pool_name $pool_health
    done
  fi
}

# general checks
check_raid

# execute subchecks
