#!/bin/sh

# Shutdown voc edition. You have to press the power button
# four times in 5 seconds to shutdown the system.

TMP_DIR="/tmp"

pressed_buttons=$(LC_NUMERIC="C" find $TMP_DIR -name 'power_button_press_*' -type f -cmin -0.083 | wc -l)

if [ $pressed_buttons -lt 3 ]; then
  touch $TMP_DIR/power_button_press_$(expr $pressed_buttons + 1)
else
  echo "Shutdown system."
  rm $TMP_DIR/power_button_press_*
  shutdown -h -P now "Power button pressed four times"
fi
