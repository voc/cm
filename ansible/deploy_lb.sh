#!/bin/sh

if [[ $* != *--deploy* && $* != *--diff* ]]; then
  echo "Generate loadbalancer config and deploy it."
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
    ansible-playbook $BASEDIR/site.yml -f 1 -u $USER -s -i $BASEDIR/event -l 'loadbalancers' --tags haproxy_deploy --check --diff
  else
    echo
    echo "Deploy new config to loadbalancers? [yes|no]"
    read choice

    if [ "$choice" = "yes" ]; then
      ansible-playbook $BASEDIR/site.yml -f 1 -u $USER -s -i $BASEDIR/event -l 'loadbalancers' --tags haproxy_deploy --diff
    else
      echo "Nothing deployed."
    fi
  fi
}

get_relay_json
create_lb_cariables
deploy_lbs

exit $?
