#!/usr/bin/env bash

[[ -n "$DEBUG" ]] && set -x
set -uo pipefail

PRIMARY="${node.metadata.get('unbound-with-knot/primary')}"
HOSTNAME="${node.metadata.get('hostname')}"
PASSWORD="${node.metadata.get('unbound-with-knot/primary_secret')}"
needs_reload=0

<%text>

if ! ping -c2 "${PRIMARY}"
then
    voc2alert "warn" "knot" "Could not reach ${PRIMARY}, not updating!"
    exit 0
fi

set -e

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
        voc2alert "error" "knot" "Downloaded new config from ${PRIMARY} with SHA1 hash '${sha1_new}', but 'knot -c' did not verify it!"
        exit 1
    fi

    mv /etc/knot/knot.conf.new /etc/knot/knot.conf

    if systemctl is-active --quiet knot
    then
        systemctl reload knot
    else
        systemctl reset-failed knot
        systemctl start knot
    fi

    voc2alert "info" "knot" "Downloaded new configuration from ${PRIMARY} with SHA1 hash '${sha1_new}'"
fi

knotc zone-refresh
</%text>
