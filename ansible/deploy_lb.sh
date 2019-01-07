#!/bin/bash


if [[ $* != *--deploy* && $* != *--diff* ]]; then
  echo "Generate loadbalancer config and deploy it."
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

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function get_relay_json() {
  wget -O $BASEDIR/relays.json https://voc:${PASSWORD}@c3voc.de/relayregister/relays
}

function create_lb_cariables() {
  file_pattern="# DO NOT EDIT MANUALLY BELOW THAT LINE"

  # remove current variables
  sed -ie "/${file_pattern}/Q" $BASEDIR/group_vars/loadbalancers
  # insert matching pattern line
  echo $file_pattern >> $BASEDIR/group_vars/loadbalancers
  # write config
  perl $BASEDIR/register2lb.pl $BASEDIR/relays.json >> $BASEDIR/group_vars/loadbalancers
  echo "Pushed changes into $BASEDIR/group_vars/loadbalancers:"
  cat  $BASEDIR/group_vars/loadbalancers
}

function deploy_lbs() {
  if [[ $DIFF = true ]]; then
    $BASEDIR/ansible-playbook-keepass $BASEDIR/site.yml -f 1 -u $USER -b -i $BASEDIR/event -l 'loadbalancers' --tags haproxy_deploy --check --diff
  else
    echo
    echo "Deploy new config to loadbalancers? [yes|no]"
    read choice

    if [ "$choice" = "yes" ]; then
      $BASEDIR/ansible-playbook-keepass $BASEDIR/site.yml -f 1 -u $USER -b -i $BASEDIR/event -l 'loadbalancers' --tags haproxy_deploy --diff
    else
      echo "Nothing deployed."
    fi
  fi
}

get_relay_json
create_lb_cariables
deploy_lbs

exit $?
