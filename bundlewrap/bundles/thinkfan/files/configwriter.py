#!/usr/bin/env python3

from subprocess import check_output

CONFIG_TEMPLATE = """{hwmon}

tp_fan /proc/acpi/ibm/fan

# (level, mintemp, maxtemp)
(3, 0,  31)
(4, 29, 41)
(5, 39, 51)
(6, 49, 56)
(7, 54, 61)
(127, 59, 32767)
"""

hwids = check_output(['find', '/sys/devices/platform', '-type', 'f', '-iname', 'temp*_input']).decode().splitlines()

with open('/etc/thinkfan.conf', 'w') as f:
    f.write(CONFIG_TEMPLATE.format(
        hwmon='\n'.join([
            f'hwmon {i}' for i in sorted(hwids)
        ]),
    ))
