#!/bin/bash
# Forwards an mkv stream to another icecast

while getopts "s:d:n:h" opt; do
  case $opt in
    s)
      SRC=${OPTARG}
      ;;
    d)
      DST=${OPTARG}
      ;;
    h)
      SHOW_HELP=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ ${SHOW_HELP} || ! ${SRC} || ! ${DST} ]]; then
  NAME=`basename "${0}"`
  echo "usage: ${NAME} -s SRC -d DST
  -s SRC - Source Host e.g. 1.2.3.4:7999/s1
  -d DST - Destination Host e.g. source:foo@localhost:7999/s1
  -h - Show this help"
  exit 1
fi

ffmpeg -y -i "http://${SRC}" -threads 0 \
        -c:v copy -c:a copy -map 0 \
        -f matroska -ice_public 1 -content_type video/webm icecast://${DST}
