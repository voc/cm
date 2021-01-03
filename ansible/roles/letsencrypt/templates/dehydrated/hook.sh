#!/usr/bin/env bash

#
# Deploy a DNS challenge using nsupdate
#

set -e
set -u
set -o pipefail
shopt -s nullglob

TTL=300

case "$1" in
    "deploy_challenge")
        {% if use_lednsapi %}
        echo " + Adding challenge token to DNS..."
        response="$(curl -s "https://lednsapi.c3voc.de/lednsapi/set" -F "secret=@/etc/dehydrated/lednsapi.secret" -F "domain=${2}" -F "token=${4}")"
        if [ ! "${response}" = "OK" ]; then
            echo "Error deploying tokens:"
            echo "${response}"
            exit 1
        fi
        {% endif %}
        ;;
    "clean_challenge")
        {% if use_lednsapi %}
        echo " + Deleting challenge token from DNS..."
        response="$(curl -s "https://lednsapi.c3voc.de/lednsapi/clear" -F "secret=@/etc/dehydrated/lednsapi.secret" -F "domain=${2}" -F "token=${4}")"
        if [ ! "${response}" = "OK" ]; then
            echo "Error deleting tokens:"
            echo "${response}"
            exit 1
        fi
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
