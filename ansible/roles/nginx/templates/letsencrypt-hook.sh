#!/usr/bin/env bash

deploy_ocsp() {
  local DOMAIN="${1}" OCSPFILE="${2}"
  local DEPLOYPATH="/etc/ssl/certs/${DOMAIN}.pem.ocsp"
  cp "${OCSPFILE}" "${DEPLOYPATH}"
  chown root:ssl-cert "${DEPLOYPATH}"
  chmod g+r "${DEPLOYPATH}"
  systemctl reload nginx
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_ocsp)$ ]]; then
  "$HANDLER" "$@"
fi