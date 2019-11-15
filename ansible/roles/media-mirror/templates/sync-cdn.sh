#!/bin/bash

LOCK=/run/lock/media-sync.lock

if ! lockfile-create -p -l $LOCK ; then
    /usr/bin/logger -t "$(basename $0)[$$]" "Lock file for pid $(cat $LOCK) exists."
    exit 1
fi

lockfile-touch -l $LOCK &
BADGER="$!"

trap "kill $BADGER ; lockfile-remove -l $LOCK" INT TERM EXIT

  # begin
  RSYNC_PASSWORD={{ rsync_password }} rsync -Pa --bwlimit=42230 -x -4 \
    --exclude "lost+found" \
    {{ rsync_cdn_url }} /srv/ftp
  # end

kill $BADGER
lockfile-remove -l $LOCK
trap - INT TERM EXIT
exit 0
