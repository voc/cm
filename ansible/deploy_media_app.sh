#!/bin/bash

if [ -z "$KEEPASS_PW" ]; then
  echo "need keepass pw"
  exit 1
fi

env KEEPASS="$KEEPASS" KEEPASS_PW="$KEEPASS_PW" $(command -v  python) lookup_plugins/keepass.py
env KEEPASS="$KEEPASS" KEEPASS_PW="$KEEPASS_PW" ansible-playbook -i inventory/media media-app.yml -v $*
