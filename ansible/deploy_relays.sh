#!/bin/bash

if [[ $* != *--deploy* && $* != *--pretend* ]]; then
  echo "Generate relay configs and deploy it."
  echo
  echo "Usage: $0 --deploy or --pretend"
  exit 1
fi

if [[ $* = *--pretend* ]]; then
  PRETEND=true
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# fetch relay json from register
function get_relay_json() {
  pass=$(KEEPASS_PW=${KEEPASS_PW} python ${DIR}/lookup_plugins/keepass.py ansible/stream-api/relay-register.password)
  wget -O $DIR/relays.json https://voc:${pass}@c3voc.de/relayregister/relays
}

# deploy edge relays
function deploy_relays() {
  if [[ $PRETEND = true ]]; then
    $DIR/ansible-playbook-keepass $DIR/site.yml -f 1 -u $USER -b -i $DIR/event -l 'edge_relays' --tags icecast,nginx,iptables,letsencrypt,relay --check --diff
  else
    echo
    echo "Deploy new config on relays? [yes|no]"
    read choice

    if [ "$choice" = "yes" ]; then
      $DIR/ansible-playbook-keepass $DIR/site.yml -f 1 -u $USER -b -i $DIR/event -l 'edge_relays' --tags icecast,nginx,iptables,letsencrypt,relay --diff
    else
      echo "Nothing deployed."
    fi
  fi
}

# get keepass info
source _ansible_keepass_util.sh
set_keepass_dir
ask_keepass_password

get_relay_json
perl register2ansible.pl relays.json > inventory/relays.ini
deploy_relays

exit $?
