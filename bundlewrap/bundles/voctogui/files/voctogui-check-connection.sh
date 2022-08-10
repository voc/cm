#!/usr/bin/env bash

response=$(echo "message ping" | nc -w1 ${encoder_ip} 9999)

if [ "$response" == "message ping" ]
then
    exit 0
else
    exit 1
fi
