#!/bin/bash
ssh $1 "sudo systemctl stop consul nebula@nebula; sudo rm -r /var/lib/consul /etc/machine-id; sudo systemd-machine-id-setup; sudo nix-shell -p ssh-to-age --command 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'"
