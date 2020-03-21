#!/bin/bash


# pip install pykeepass libkeepass ansible
# ansible-galaxy install -r requirements.yml

# ~/.ansible.cfg
# [ssh_connection]
# pipelining = True


# TODO voc user should have a sudo password and use -K?
if [ -z "$KEEPASS_PW" ]; then
  echo "need keepass pw"
  exit 1
fi

env KEEPASS="$KEEPASS" KEEPASS_PW="$KEEPASS_PW" $(command -v  python) lookup_plugins/keepass.py
# --become -u voc
env KEEPASS="$KEEPASS" KEEPASS_PW="$KEEPASS_PW" ansible-playbook -i media media-cdn.yml -v --ssh-extra-args="-A" $*
