throttle_messages=$(echo "$KERNEL_LOG" | grep -ciF "cpu clock throttled")
if [ "$throttle_messages" -gt "0" ]; then
    voc2alert "error" "kernel" "CPU throttled! (message appeared ${throttle_messages} times in the last 10 minutes)"
fi
