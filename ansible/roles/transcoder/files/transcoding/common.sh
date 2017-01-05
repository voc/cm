#!/bin/bash
. config.sh

parse_stream(){
  echo "${1}" | sed -e 's/^s\([0-9]\+\)_.\+$/\1/g'
}

get_src(){
  echo ${ENCODERS[${1}]}
}

STREAM="${1}"
STREAM_ROOM=$(parse_stream ${STREAM})
SRC=$(get_src ${STREAM_ROOM})
