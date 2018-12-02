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
        printf "server %s\nupdate add _acme-challenge.%s. %d in TXT \"%s\"\nsend\n" "${DNSSERVER}" "${DOMAIN}" "${TTL}" "${4}" | $NSUPDATE
        sleep 5
        ;;
    "clean_challenge")
        printf "server %s\nupdate delete _acme-challenge.%s. %d in TXT \"%s\"\nsend\n" "${DNSSERVER}" "${DOMAIN}" "${TTL}" "${4}" | $NSUPDATE
        ;;
    "deploy_cert")
        # optional:
        # /path/to/deploy_cert.sh "$@"
        DOMAIN="${2}"
        chmod g+r /etc/letsencrypt/live/${DOMAIN}/*
        for f in /etc/letsencrypt/renewal-hooks/post/*; do $f; done
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
    *)
        echo "Warning: Unknown hook '$1'"
        ;;
esac

exit 0
