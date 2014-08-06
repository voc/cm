#!/bin/bash

xset -dpms
xset s off

synclient TouchpadOff=1

xrdb -load /home/mixer/.Xresources

runsvdir /home/mixer/services/ &
dwm-voc
