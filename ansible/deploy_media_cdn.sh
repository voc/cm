#!/bin/bash

#[ -d roles/ansible-acmetool ] || git clone https://github.com/artefactual-labs/ansible-acmetool.git roles/
ansible-galaxy install -r requirements.yml

# TODO voc user should have a sudo password and use -K?
# TODO replace -e "@media.secrets with keepass
if [ -z "$KEEPASS_PW" ]; then
  echo "need keepass pw"
  exit 1
fi

env KEEPASS="$KEEPASS" KEEPASS_PW="$KEEPASS_PW" $(command -v  python) lookup_plugins/keepass.py
# --become -u voc
env KEEPASS="$KEEPASS" KEEPASS_PW="$KEEPASS_PW" ansible-playbook -i media -e '@media.secrets' media.yml -v --ssh-extra-args="-A" $*
