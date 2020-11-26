#!/usr/bin/env bash

#
# Deploy a DNS challenge using nsupdate
#

set -e
set -u
set -o pipefail
shopt -s nullglob

TTL=300

if [ "$1" = "deploy_challenge" -o "$1" = "clean_challenge" ]; then
        DOMAIN="${2}"
        NSUPDATE="nsupdate -d -k /etc/dehydrated/dns-01-key.private"
        DNSSERVER="mngslave.dus.c3voc.de"
fi

case "$1" in
    "deploy_challenge")
        {% if use_dns %}
        printf "server %s\nupdate add _acme-challenge.%s. %d in TXT \"%s\"\nsend\n" "${DNSSERVER}" "${DOMAIN}" "${TTL}" "${4}" | $NSUPDATE
        sleep 5
        {% endif %}
        ;;
    "clean_challenge")
        {% if use_dns %}
        printf "server %s\nupdate delete _acme-challenge.%s. %d in TXT \"%s\"\nsend\n" "${DNSSERVER}" "${DOMAIN}" "${TTL}" "${4}" | $NSUPDATE
        {% endif %}
        ;;
    "deploy_cert")
        # do nothing for now
        ;;
    "unchanged_cert")
        # do nothing for now
        ;;
    "startup_hook")
        # do nothing for now
        ;;
    "exit_hook")
        # do nothing for now
        ;;
esac

# call custom sub-hooks
for file in /etc/dehydrated/hook.d/*.sh; do
  if [ -x "${file}" ]; then
    "${file}" "$@"
  fi
done

exit 0
