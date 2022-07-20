#!/bin/sh

# I'm sorry…

# limits
LIMIT_DISK_USAGE=90
LIMIT_DISK_MIN_FREE_SPACE_KB=9765625
LIMIT_LOAD=$(echo "$(grep processor /proc/cpuinfo | wc -l) * 2" | bc)

TRUNC_HOSTNAME=$(hostnamectl --static | cut -d. -f1-2)

HYPERVISOR=$(systemd-detect-virt)
if [ $? -ne 0 ]; then
	# When no virtualization is detected, systemd-detect-virt outputs
	# "none", which is not as nice to check for. Set to empty string
	# instead.

	HYPERVISOR=""
fi

send_mqtt_message () {
  error_level=$1
  component=$2
  message=$3

  if [ -n "$DEBUG" ]; then
    echo mosquitto_pub --capath /etc/ssl/certs/ -h \"{{ mqtt.server }}\" -u \"{{ mqtt.username }}\" -P \"{{ mqtt.password }}\" -t \"/voc/alert\" -m \"{\\\"level\\\":\\\"${error_level}\\\",\\\"component\\\":\\\"${component}\\\",\\\"msg\\\":\\\"${message}\\\"}\"
  else
    for i in 1 2 3 ; do
      mosquitto_pub --capath /etc/ssl/certs/ -h "{{ mqtt.server }}" -p 8883 -u "{{ mqtt.username }}" -P "{{ mqtt.password }}" -t "/voc/alert" -m "{\"level\":\"${error_level}\",\"component\":\"${component}\",\"msg\":\"${message}\"}" && break
    done
  fi
}

debug_output() {
  if [ "$DEBUG" = "true" ]; then
    for param in "$@"; do
      printf $param,
    done

    echo
  fi
}

check_disk_space () {
  df -h | tail -n +2 | while read line; do
    device=$(echo $line | awk '{ print $1 }')
    disk_usage_percent=$(echo $line | awk '{ print $5 }' | tr -d '%')
    disk_space=$(echo $line | awk '{ print $2 }')
    disk_space_avilable=$(echo $line | awk '{ print $4 }')
    mount_point=$(echo $line | awk '{ print $6 }')


    if [ "$disk_usage_percent" -ge "$LIMIT_DISK_USAGE" ]; then
      space_free_kb=$(df ${mount_point} | tail -n+2 | awk '{ print $4 }')
      if [ "$space_free_kb" -le "$LIMIT_DISK_MIN_FREE_SPACE_KB" ]; then
        send_mqtt_message "error" "system/disk/${TRUNC_HOSTNAME}" "<red>$device: disk usage $disk_usage_percent%, only $disk_space_avilable left of $disk_space</red>"
      fi
    fi

    debug_output "df" $device $disk_usage_percent $disk_space $disk_space_avilable
  done
}


check_load () {
  local load_1_minute=$(cut -d' ' -f 1 /proc/loadavg)
  local load_5_minutes=$(cut -d' ' -f 2 /proc/loadavg)
  local load_15_minutes=$(cut -d' ' -f 3 /proc/loadavg)

  local truncated_load=$(echo "$load_5_minutes" | cut -d. -f1)

  if [ "$truncated_load" -ge "$LIMIT_LOAD" ]; then
    send_mqtt_message "error" "system/load/${TRUNC_HOSTNAME}" "system load: $load_1_minute, $load_5_minutes, $load_15_minutes</red>"
  fi

  debug_output "load" $load_1_minute $load_5_minutes $load_15_minutes $truncated_load
}

# check_raid implements:
#
#  * mdadm status of existing md devices
#  * megacli raid controller status via wrapper raidstatus
#    (available e.g. on storage and ${TRUNC_HOSTNAME})
#  * megacli battery status via wrapper raidstatus
#
check_raid () {
  if [ -e "/proc/mdstat" ]; then
    cat /proc/mdstat | awk '/^md/ {printf "%s: ", $1}; /blocks/ {print $NF}' | while read line; do
      raid_device=$(echo $line | cut -d ":" -f 1)
      raid_device_state=$(echo $line | cut -d " " -f 2)

      echo $raid_device_state | grep -q "_"
      if [ "0" -eq "$?" ]; then
        send_mqtt_message "error" "system/raid/${TRUNC_HOSTNAME}" "<red>RAID disk failed: $raid_device: $raid_device_state"
      fi

      debug_output "mdadm" $raid_device $raid_device_state
    done
  fi

  if [ -e "/usr/local/sbin/raidstatus" ]; then
    raid_status=$(raidstatus status | grep -v "Current" | grep "State")
    if [ "0" -eq "$?" ]; then
      echo $raid_status | grep -q "Optimal"
      if [ "1" -eq "$?" ]; then
        send_mqtt_message "error" "system/raid/${TRUNC_HOSTNAME}" "<red>RAID status is not 'Optimal': please run 'raidstatus status' for more information</red>"
      fi
    fi

    bat_status=$(raidstatus bat | grep "Battery State:")
    echo $bat_status | grep -q "Optimal"
    if [ "0" -eq "$?" ]; then
      if [ "1" -eq "$?" ]; then
        send_mqtt_message "error" "system/raid/${TRUNC_HOSTNAME}" "<red>RAID battery status is not 'Optimal': please run 'raidstatus bat' for more information</red>"
      fi
    fi

    debug_output "raid_status" $raid_status $bat_status
  fi

  if [ -e "$(command -v zpool)" ] && [ "$(lsmod | grep -q zfs; echo $?)" -eq "0" ];then
    zpool list -H | while read line; do
      pool_name=$(echo $line| awk  '{ print $1 }')
      pool_health=$(echo $line| awk  '{ print $9 }')

      echo $pool_health | grep -iqE 'online'
      if [ "$?" -ne "0" ]; then
        send_mqtt_message "error" "system/zfs/${TRUNC_HOSTNAME}" "<red>ZFS pool '${zfs_pool}' is '${pool_health}' please run 'zpool status' for more information</red>"
      fi

      debug_output "zfs" $pool_name $pool_health
    done
  fi
}


# check_logs implements:
#   It checks the kernel logs generated in the last 10 minutes according to the
#   following errors:
#
#     * OOM situations
#     * hanging tasks for more then 120 seconds
#     * CPU throttling
#
check_logs () {
  kernel_log=$(journalctl _TRANSPORT=kernel --since "10 minutes ago")

  task_blocked=$(echo $kernel_log | grep -q "blocked for more than")
  if [ "0" -eq "$?" ]; then
    send_mqtt_message "error" "system/kernel/${TRUNC_HOSTNAME}" "<red>Task '$(echo $task_blocked | awk '{ print $8 }' | xargs | tr ' ' ',')' blocked for more than 120 seconds.</red>"
  fi

  oom_messages=$(echo $kernel_log | grep -q "Out of memory")
  if [ "0" -eq "$?" ]; then
    send_mqtt_message "error" "system/kernel/${TRUNC_HOSTNAME}" "<red>OOM killer killed processes!</red>"
  fi

  # don't check cpu throttleing on minions
  if [ "1" -eq "$(hostnamectl status --static | grep -q "minion"; echo $?)" ]; then
    throttle_messages=$(echo $kernel_log | grep -q "cpu clock throttled")
    if [ "0" -eq "$?" ]; then
      send_mqtt_message "error" "system/kernel/${TRUNC_HOSTNAME}" "<red>CPU throttled!</red>"
    fi
  fi

  debug_output "log" $task_blocked $oom_messages $throttle_messages
}


# check_interfaces implements:
#
#   * full-duplex check
#   * line speed test for at least 1gbit
#
# limitations:
#
#   * check only work on real hardware.
#   * ignored interfaces:
#     + down status
#     + with tags
#     + bridges
#     + loopback
#  * no bond status check
#
check_interfaces () {
  for interface in $(grep "iface" /etc/network/interfaces | grep -vE "iface lo |#|br|bond.*\..*|monitoring-ignore-me" | awk '{ print $2 }' | sed 's|:.*$||g' | sort | uniq); do
    if [ "$(systemd-detect-virt)" = "none" ] && [ "$(grep -q up /sys/class/net/${interface}/operstate; echo $?)" -eq "0" ]; then
      # we need at least 1gbit
      if [ -e "/sys/class/net/${interface}/speed" ]; then
        if [ "$(cat /sys/class/net/${interface}/speed)" -lt "1000" ]; then
          send_mqtt_message "error" "system/interface/${interface}/${TRUNC_HOSTNAME}" "<red>${interface} has lass then 1Gbit/s</red>"
        fi
      fi
      # we need full-dumplex
      if [ -e "/sys/class/net/${interface}/duplex" ]; then
        if [ "$(grep -q "full" /sys/class/net/${interface}/duplex; echo $?)" -eq "1" ]; then
          send_mqtt_message "error" "system/interface/${interface}/${TRUNC_HOSTNAME}" "<red>${interface} runs not in full-dumplex mode!</red>"
        fi
      fi

      debug_output "interface" $interface "$(cat /sys/class/net/${interface}/duplex)" "$(cat /sys/class/net/${interface}/speed)"
    fi
  done
}


# check_temperature implements:
#   * intel cpu temperature with coretemp
check_temperature () {
  if [ -d "/sys/class/hwmon/hwmon0" ]; then
    for hwmon in $(ls -d /sys/class/hwmon/hwmon*); do
      if [ ! -e "${hwmon}/name" ]; then
        break;
      fi
      if [ $(cat ${hwmon}/name) = "coretemp" ]; then
        for temp in $(ls ${hwmon}/temp*_label | grep -o "temp."); do
          if [ ! -e "${hwmon}/${temp}_input" ] || [ ! -e "${hwmon}/${temp}_crit" ]; then
            break;
          fi

          value="$(cat ${hwmon}/${temp}_input)"
          limit="$(cat ${hwmon}/${temp}_crit)"

          debug_output "temp" $temp $value $limit
          if [ $(echo "${value} > (${limit}*0.95)" | bc) -eq "1" ]; then
            label="$(cat ${hwmon}/${temp}_label)"

            # Don't send temp messages for minions. Possible occurrence of smoke
            # from the device is normal and harmless.
            if [ "1" -eq "$(hostnamectl status --static | grep -q "minion"; echo $?)" ]; then
              send_mqtt_message "error" "system/temp/${TRUNC_HOSTNAME}" "<red>${label} temp critical at $(echo "${value}/1000" | bc) °C</red>"
            fi
            break 2
          fi

        done
      fi
    done
  fi
}


# check_updates implements:
#
# * runs 'apt update'
# * parse avaible upgradable packes from output
#
check_updates () {
  updates=$(apt update 2>/dev/null  | grep "can be upgraded")
  if [ "0" -eq "$?" ]; then
    send_mqtt_message "error" "system/updates/${TRUNC_HOSTNAME}" "<yellow>$(echo $updates | cut -d '.' -f 1).</yellow> <red>Uptime:</red> <yellow>$(uptime | cut -d ',' -f 1)</yellow>"
  fi
}


# send system uptime in every run
ping () {
  primary_ip="$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)"
  uptime="$(cat /proc/uptime | awk '{ print $1 }')"
  for i in 1 2 3 ; do
    mosquitto_pub --capath /etc/ssl/certs/ -h "{{ mqtt.server }}" -p 8883 -u "{{ mqtt.username }}" -P "{{ mqtt.password }}" -t "/voc/checkin" -m "{ \"name\": \"${TRUNC_HOSTNAME}\", \"interval\": \"60\", \"additional_data\": { \"uptime\": ${uptime} }}" && break
  done
  debug_output "ping" $hostname $uptime
}

# inform watchdog about graceful shutdown
shutdown () {
  primary_ip="$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)"

  for i in 1 2 3 ; do
    mosquitto_pub --capath /etc/ssl/certs/ -h "{{ mqtt.server }}" -p 8883 -u "{{ mqtt.username }}" -P "{{ mqtt.password }}" -t "/voc/shutdown" -m "{ \"name\": \"${TRUNC_HOSTNAME}\"}" && break
  done

  debug_output "shutdown" $hostname
}

# Check voc related websites
check_http () {
  http_urls="https://streaming.media.ccc.de https://c3voc.de https://c3voc.de/wiki https://tracker.c3voc.de https://c3voc.de/eventkalender"

  for url in $(echo $http_urls); do
    error_code=$(curl -I ${url} 2>/dev/null | head -n1 | cut -d ' ' -f 2)
    if [ -z "${error_code}" ]; then
      break
    fi

    # remove unneeded stuff
    error_code=$(echo $error_code | tr '\r' ' ')

    if [ "$error_code" = "html>" ]; then
      send_mqtt_message "error" "system/http/${TRUNC_HOSTNAME}" "<yellow>${url}</yellow><red>: website br0ken</red>"
    elif  [ "$error_code" -gt "302" ]; then
      send_mqtt_message "error" "system/http/${TRUNC_HOSTNAME}" "<yellow>${url}</yellow><red>: error code </red><yellow>${error_code}</yellow>"
    fi
    sleep 1
  done
}

# check for failed systemd services
check_systemd () {
  res="$(LANG=C systemctl list-units --state=failed --no-legend --no-pager | sed 's/^\* //g')"
  if [ -n "${res}" ]; then
    echo "${res}" | while read line; do
      service="$(echo "${line}" | awk '{print $1}')"
      debug_output "systemd" "${TRUNC_HOSTNAME}" "${service}"
      send_mqtt_message "error" "system/systemd/${TRUNC_HOSTNAME}" "<red>systemd unit ${service} failed</red>"
    done
  fi
}

# check if system is running on battery and the capacity is <= 30%
check_ac_power () {
  if [ -f "/sys/class/power_supply/AC/online" ]; then
    ac_online=$(cat /sys/class/power_supply/AC/online)
    if [ -f "/sys/class/power_supply/BAT0/capacity" ]; then
      bat0_capacity=$(cat /sys/class/power_supply/BAT0/capacity)
    else
      bat0_capacity="-1"
    fi
    [ "0" -eq "$ac_online" ] && [ "$bat0_capacity" -le 30 ] && send_mqtt_message "error" "system/power/${TRUNC_HOSTNAME}" "<red>AC power offline! Battery $bat0_capacity % left.</red>"
  fi
}

# no checks on shutdown
if [ "$1" = "shutdown" ] ; then
	shutdown
	exit 0
fi

# general checks
ping
check_load
check_disk_space
check_raid
check_logs
#check_interfaces
check_systemd
check_ac_power

# special cases
# only check temperature on real hardware
if [ -z "${HYPERVISOR}" ]; then
  check_temperature
fi
# check for updates every month 23rd 20:42
if [ "232042" = "$(date +'%e%H%M')" ]; then
  check_updates
fi

if [ "mng.ber.c3voc.de" = "$(hostname -f)" ]; then
  check_http
fi

# execute subchecks
for file in /usr/local/sbin/check_system.d/*.sh
do
  if [ -x "${file}" ]; then
    . "${file}"
  fi
done

exit 0
