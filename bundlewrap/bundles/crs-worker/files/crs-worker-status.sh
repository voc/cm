% for worker in sorted(scripts):
# ${worker}
if ! systemctl is-active --quiet "crs-${worker}"
then
    voc2alert "error" "crs-worker/${worker}" "worker ${worker} is not running!"
fi
% endfor
