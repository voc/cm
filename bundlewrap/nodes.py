from json import dumps as json_dumps
from os.path import join
from pathlib import Path

import bwkeepass as keepass

from bundlewrap.metadata import atomic
from bundlewrap.utils import error_context


for node in Path(join(repo_path, "nodes")).rglob("*.py"):
    with error_context(filename=str(node)):
        with open(node, 'r') as f:
            exec(f.read())

for name, data in nodes.items():
    data.setdefault('hostname', '.'.join(reversed(name.split('.'))) + '.lan.c3voc.de')
    data.setdefault('metadata', {}).setdefault('hostname', '.'.join(reversed(name.split('.'))) + '.lan.c3voc.de')
    data.update(libs.demagify.demagify(data))
