#!/usr/bin/env bash

deploy_cert() {
  local DOMAIN="${1}"
  local TARGET="/etc/letsencrypt/live/${DOMAIN}/haproxy.pem"

  cp /dev/null $TARGET
  chmod 660 $TARGET
  cat "/etc/letsencrypt/live/${DOMAIN}/cert.pem" >> $TARGET
  echo >> $TARGET
  cat "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" >> $TARGET
  echo >> $TARGET
  cat "/etc/letsencrypt/live/${DOMAIN}/chain.pem" >> $TARGET
  echo >> $TARGET
  cat /etc/ssl/dhparam2048.pem >> $TARGET

  # chown root:ssl-cert "${TARGET}"
  # chmod g+r "${TARGET}"
  systemctl reload haproxy
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_cert)$ ]]; then
  "$HANDLER" "$@"
fi