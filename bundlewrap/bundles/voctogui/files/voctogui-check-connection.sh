#!/usr/bin/env bash

response=$(echo "message ping" | nc -w1 10.73.${room_number}.3 9999)

if [ "$response" == "message ping" ]
then
    exit 0
else
    exit 1
fi
