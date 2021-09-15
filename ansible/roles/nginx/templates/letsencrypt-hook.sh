#!/usr/bin/env bash

deploy_cert() {
  DOMAIN="${1}"
  # allow read for ssl-cert group
  chmod g+r /etc/letsencrypt/live/${DOMAIN}/*
  systemctl reload nginx
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_cert)$ ]]; then
  "$HANDLER" "$@"
fi