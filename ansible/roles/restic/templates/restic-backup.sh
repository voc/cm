#!/bin/sh
PATH=$PATH:/usr/local/bin

set -e

export RESTIC_REPOSITORY="sftp:{{restic_user}}@{{restic_host}}:{{restic_repo}}/{{restic_host_repo}}"
export RESTIC_PASSWORD="{{restic_password}}"

if [ ! -z "$1" ]; then
  restic $*
  exit 0
fi

restic backup \
  {{restic_options}}

restic forget \
  --keep-hourly 12 \
  --keep-daily 7 \
  --keep-weekly 5 \
  --keep-monthly 6 \
  --prune
