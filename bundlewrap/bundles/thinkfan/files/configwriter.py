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

filtered_hwids = set()
hwids = check_output(['find', '/sys/devices/platform', '-type', 'f', '-iname', 'temp*_input']).decode().splitlines()

for hwid in hwids:
    try:
        with open(hwid) as f:
            # atleast on mixer96, temp2_input exists, but does fail when reading
            f.read()
        filtered_hwids.add(hwid)
    except Exception as e:
        print(f'could not open {hwid} for reading: {e!r}')

with open('/etc/thinkfan.conf', 'w') as f:
    f.write(CONFIG_TEMPLATE.format(
        hwmon='\n'.join([
            f'hwmon {i}' for i in sorted(filtered_hwids)
        ]),
    ))
