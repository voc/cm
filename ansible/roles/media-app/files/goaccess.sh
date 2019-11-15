#!/bin/sh
date=$(date +%s)
cp /srv/www/media.ccc.de/stats/nginx.html /srv/www/media.ccc.de/stats/nginx_$date.html
zcat -f /var/log/nginx/access.log /var/log/nginx/access.log.1 /var/log/nginx/access.log.[234].gz | goaccess - -a -o /srv/www/media.ccc.de/stats/nginx.html
# --load-from-disk --keep-db-files
