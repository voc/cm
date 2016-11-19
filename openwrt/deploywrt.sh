#!/bin/bash -x
#
# Utility to deploy a router config onto an openwrt user. Assumes that
# the router has a vanilla installation and is initially reachable
# through the ip given
#
# Usage: ./deploywrt.sh <ip> <room>

[ $# -lt 3 ] && echo "Usage: ./deploywrt.sh <ip> <room> password" && exit

ip="$1"
room="$2"
password="$3"

fill_template() {
  local source="$1"
  local dest="$2"
  sed "s,%ROOM%,$room,g" "templates/$source" > "$dest"
}

transfer_path_recursive() {
  local path=$1
  sshpass -p "$password" scp -r "$path" "root@$ip:/"
}

copy_templates() {
  local templates=$(cd templates; find . -type f)
  for template in $templates; do
    fill_template "$template" "$1/$template"
  done
}

copy_static() {
  (cd static; cp -r * "$1")
}

copy_certificates() {
  cp certificates/wrt${room}@mng.ber.c3voc.de.{crt,key} ${1}/etc/openvpn
  ## TODO: properly decrypt with gpg
}

sshwrapper() {
  sshpass -p "$password" ssh "$1"
}

install_packages() {
  packages=$(cat packages)
  sshwrapper "root@$ip" opkg update
  sshwrapper "root@$ip" opkg install "$packages"
}

reboot_device() {
  sshwrapper "root@$ip" reboot
}

if [ -z $(which sshpass) ]; then
  echo "Please install sshpass"
  exit -1
fi

tempdir="$(mktemp -d)"

install_packages
copy_static $tempdir
copy_templates $tempdir
copy_certificates $tempdir
transfer_path_recursive $tempdir
reboot_device

#echo $tempdir
rm -rf "$tempdir"
