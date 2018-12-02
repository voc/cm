#!/bin/sh


if [[ $* != *--deploy* && $* != *--diff* ]]; then
  echo "Generate relay configs and deploy it."
  echo
  echo "Usage: $0 --deploy or --diff"
  exit 1
fi

if [ -z "${PASSWORD}" ]; then
  echo -n "Relay register voc password: "
  read -rs PASSWORD
fi

if [[ $* = *--diff* ]]; then
  DIFF=true
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function get_relay_json() {
  wget -O $DIR/relays.json https://voc:${PASSWORD}@c3voc.de/relayregister/relays
}

function deploy_relays() {
  if [[ $DIFF = true ]]; then
    $DIR/ansible-playbook-keepass $DIR/site.yml -f 1 -u $USER -s -i $DIR/relays -l 'edges' --tags icecast,nginx,iptables,letsencrypt --check --diff
  else
    echo
    echo "Deploy new config on relays? [yes|no]"
    read choice

    if [ "$choice" = "yes" ]; then
      $DIR/ansible-playbook-keepass $DIR/site.yml -f 1 -u $USER -s -i $DIR/relays -l 'edges' --tags icecast,nginx,iptables,letsencrypt --diff
    else
      echo "Nothing deployed."
    fi
  fi
}

deploy_relays

exit $?
