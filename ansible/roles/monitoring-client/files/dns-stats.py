#!/usr/bin/env python3

import subprocess
import json

statout = subprocess.check_output(["knotc", "stats"]).decode()

stats = {}
for line in statout.splitlines():
    line = line.strip()
    if not line:
        continue
    key, value = line.replace(".", "_").replace("-", "_").replace("[", "_").replace("]", "").split(" = ", 1)
    stats[key] = int(value)

print(json.dumps(stats))
