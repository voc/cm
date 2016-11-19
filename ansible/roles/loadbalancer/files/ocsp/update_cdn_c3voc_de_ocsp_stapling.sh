#!/bin/sh

openssl ocsp -noverify -issuer /etc/ssl/certs/sub.class1.server.sha2.ca.pem \
  -cert /etc/ssl/certs/cdn.c3voc.de.crt \
  -url http://ocsp.startssl.com/sub/class1/server/ca \
  -no_nonce -header Host ocsp.startssl.com \
  -respout /etc/ssl/certs/haproxy_cdn.c3voc.de.pem.ocsp
