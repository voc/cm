#!/bin/bash

. common.sh

SUFFIX="$2"

oggfwd -w 127.0.0.1 7999 source /"s${STREAM_ROOM}_${SUFFIX}.mkv"

