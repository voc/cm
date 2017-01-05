#!/bin/sh

if [[ $* != *--deploy* && $* != *--diff* ]]; then
  echo "Generate relay configs and deploy it."
  echo
  echo "Usage: $0 --deploy or --diff"
  exit 1
fi

if [[ $* = *--diff* ]]; then
  DIFF=true
fi

BASEDIR=$(dirname "$0")

function get_relay_json() {
  wget -O $BASEDIR/relays.json https://voc:Sondamuell23@c3voc.de/33c3/register/relays
}

function deploy_relays() {
  if [[ $DIFF = true ]]; then
    ansible-playbook $BASEDIR/site.yml -f 1 -u $USER -s -i $BASEDIR/relays -l 'edges' --tags icecast,nginx,iptables --check --diff
  else
    echo
    echo "Deploy new config on relays? [yes|no]"
    read choice

    if [ "$choice" = "yes" ]; then
      ansible-playbook $BASEDIR/site.yml -f 1 -u $USER -s -i $BASEDIR/relays -l 'edges' --tags icecast,nginx,iptables --diff
    else
      echo "Nothing deployed."
    fi
  fi
}

deploy_relays

exit $?
