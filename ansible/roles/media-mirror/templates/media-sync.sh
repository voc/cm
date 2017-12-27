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
  RSYNC_PASSWORD={{ media_mirror_rsync }} rsync -Pa --bwlimit=20240 -x -4 \
    --exclude "lost+found" \
    rsync://media@cdn.media.ccc.de:/ftp/ /srv/ftp
  # end

kill $BADGER
lockfile-remove -l $LOCK
trap - INT TERM EXIT
exit 0
