#!/bin/sh

[ -d roles/ansible-acmetool ] || git clone https://github.com/artefactual-labs/ansible-acmetool.git roles/

ansible-playbook --become -u voc -K -i media media-cdn.yml -v $*
# TODO deploy media mirrors once roles are tested
# ansible-playbook -u mm -i media media-mirror.yml -v $*
