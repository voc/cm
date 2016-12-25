#!/bin/sh

if [[ $* != *--deploy* ]]; then
  echo "Generate loadbalancer config and deploy it."
  echo
  echo "Usage: $0 --deploy"
  exit 1
fi

BASEDIR=$(dirname "$0")

function get_relay_json() {
  wget -O $BASEDIR/relays.json https://voc:Sondamuell23@c3voc.de/33c3/register/relays
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
  ansible-playbook $BASEDIR/site.yml -u $USER -s -i $BASEDIR/event -l 'loadbalancers' --tags haproxy_deploy
}

get_relay_json
create_lb_cariables
deploy_lbs
