#!/usr/bin/env bash

[[ -n "$DEBUG" ]] && set -x
set -euo pipefail

PRIMARY="${node.metadata.get('unbound-with-knot/primary')}"
HOSTNAME="${node.metadata.get('hostname')}"
PASSWORD="${node.metadata.get('unbound-with-knot/primary_secret')}"
needs_reload=0

<%text>
curl -s "http://${PRIMARY}/config/${HOSTNAME}.conf.asc" | gpg --armor --batch --passphrase "${PASSWORD}" -d > /etc/knot/knot.conf.new

sha1_new="$(sha1sum /etc/knot/knot.conf.new | awk '{print $1}')"

if [[ -e "/etc/knot/knot.conf" ]]
then
    sha1_old="$(sha1sum /etc/knot/knot.conf | awk '{print $1}')"

    if [ "$sha1_old" != "$sha1_new" ]
    then
        needs_reload=1
    fi
else
    needs_reload=1
fi

if [[ "$needs_reload" -eq 1 ]]
then
    if ! knotc -c "/etc/knot/knot.conf.new" conf-check
    then
        echo "Config verify failed!"
        exit 1
    fi

    voc2alert "info" "knot" "Downloaded new configuration from ${PRIMARY} with SHA1 hash '${sha1_new}'"

    mv /etc/knot/knot.conf.new /etc/knot/knot.conf

    if systemctl is-active --quiet knot
    then
        systemctl reload knot
    else
        systemctl reset-failed knot
        systemctl start knot
    fi
fi

knotc zone-refresh
</%text>
