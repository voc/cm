echo "$KERNEL_LOG" | grep -iF "blocked for more than" | while IFS=$'\n' read line
do
    voc2alert "error" "kernel" "Task '$(echo $line | awk '{ print $8 }' | xargs | tr ' ' ',')' blocked for more than 120 seconds."
done

echo "$KERNEL_LOG" | grep -iF "out of memory" | while IFS=$'\n' read line
do
    voc2alert "error" "kernel" "${line}"
done
