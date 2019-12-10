#!/bin/bash

set -eo pipefail

case "$1" in

  redis)
    redis-cli --raw keys "cache:*" | xargs redis-cli del
    ;;

  nginx)
    find /srv/media/media-site/cache/ -type f | sudo xargs rm -v | wc -l
    ;;

  url)
    if [ -z "$2" ]; then
      echo "reset nginx cache for a single URL"
      echo "usage: $0 https://media.ccc.de"
      exit 1
    fi
    curl -sI -H 'Secret-Header: 1' "$2"
    ;;

  sprockets)
    du -sh ~media/media-site/shared/tmp/cache/assets/sprockets
    echo "run: sudo -u media -i; cd ../current && bundle exec rails tmp:cache:clear"
    ;;

  check-cache|check-nginx)
    curl -sI "$2" | grep X-Cache
    ;;

  check-puma)
    url=$( echo "$2" | sed 's@https://media.ccc.de@http://localhost:4080@' )
    curl "$url" | less
    ;;

  *)
    echo "usage: $0 redis|nginx|sprockets|url|check-cache|check-puma [https://media.ccc.de/...]" 
    exit
    ;;
esac

