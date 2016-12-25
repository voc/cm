#!/bin/sh

BASEDIR=$(dirname "$0")

function get_relay_json() {
  wget -O $BASEDIR/relays.json https://voc:Sondamuell23@c3voc.de/33c3/register/relays
}

function create_lb_cariables() {
  perl $BASEDIR/register2lb.pl $BASEDIR/relays.json

}

function deploy_lbs() {
  echo "TODO: add code to deploy replays"
}

get_relay_json
create_lb_cariables
deploy_lbs
