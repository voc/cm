res="$(LANG=C systemctl list-units --state=failed --no-legend --no-pager | sed 's/^\* //g')"
if [ -n "${res}" ]; then
    echo "${res}" | while read line; do
        service="$(echo "${line}" | awk '{print $1}')"
        voc2alert "error" "systemd/${service}" "systemd unit failed^"
    done
fi
