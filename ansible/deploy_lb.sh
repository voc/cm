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

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function get_relay_json() {
  pass=$(KEEPASS_PW=${KEEPASS_PW} python3 ${BASEDIR}/lookup_plugins/keepass.py ansible/stream-api/relay-register.password)
  wget -O ${BASEDIR}/relays.json https://voc:${pass}@c3voc.de/relayregister/relays
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
  if [[ $PRETEND = true ]]; then
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

# get keepass info
source _ansible_keepass_util.sh
set_keepass_dir
ask_keepass_password

get_relay_json
create_lb_cariables
deploy_lbs

exit $?
