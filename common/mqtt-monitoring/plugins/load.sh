LIMIT_LOAD=$(echo "$(grep processor /proc/cpuinfo | wc -l) * 2" | bc)

load_1_minute=$(cut -d' ' -f 1 /proc/loadavg)
load_5_minutes=$(cut -d' ' -f 2 /proc/loadavg)
load_15_minutes=$(cut -d' ' -f 3 /proc/loadavg)

truncated_load=$(echo "$load_5_minutes" | cut -d. -f1)

if [ "$truncated_load" -ge "$LIMIT_LOAD" ]; then
    voc2alert "error" "load" "system load: $load_1_minute, $load_5_minutes, $load_15_minutes"
fi
