#!/bin/sh

[ -d roles/ansible-acmetool ] || git clone https://github.com/artefactual-labs/ansible-acmetool.git roles/

# TODO voc user should have a sudo password and use -K?
# TODO replace -e "@media.secrets with keepass
ansible-playbook --become -u voc -i media  -e '@media.secrets' media.yml -v $*
