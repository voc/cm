#!/bin/bash

rsync=/usr/bin/rsync
lockfile=/var/tmp/rsync-media-www.lock

if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; then

  trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT

  # begin
  $rsync -Pa -x --exclude "stats" --exclude "mrtg" --exclude "lost+found" --exclude "logs" media-sync@koeln.media.ccc.de:/srv/www/media.ccc.de/ /srv/www/media.ccc.de
  # end

  rm -f "$lockfile"
  trap - INT TERM EXIT
else
  /usr/bin/logger -t "$(basename $0)[$$]" "Lock file for pid $(cat $lockfile) exists."
fi
