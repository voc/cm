if (( "$(cut -d. -f1 /proc/uptime)" > 604800 ))
then
    if [[ -f "/var/lib/bundlewrap/last_apply_commit_id" ]]
    then
        timestamp="$(date +%s -r /var/lib/bundlewrap/last_apply_commit_id)"
        limit="$(date +%s --date "28 days ago")"

        if (( "$timestamp" < "$limit" ))
        then
            dt="$(date "+%F %T" -r /var/lib/bundlewrap/last_apply_commit_id)"
            commit="$(cat /var/lib/bundlewrap/last_apply_commit_id)"
            branch="$(cat /var/lib/bundlewrap/last_apply_branch)"

            voc2alert "warn" "bundlewrap" "last apply was on ${dt} from branch ${branch} (commit id ${commit})"
        fi
    fi
fi
