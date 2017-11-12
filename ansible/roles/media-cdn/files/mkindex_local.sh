#!/bin/bash
#set -x

PATH=/usr/bin:/bin
umask 022

MAILTO="ftpmaster"

BASEDIR="/srv/ftp"
USERNAME="ftp"
GROUP="uploaders"

cd $BASEDIR
sudo -u ftp find . -type f \! -name .\* -printf "%T@ %s %p\n" 2>/dev/null | grep -v "./INDEX.gz" | sort -n | gzip -1 > INDEX.gz
chown "${USERNAME}:${GROUP}" INDEX.gz
