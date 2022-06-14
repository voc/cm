from json import dumps as json_dumps
from os.path import join
from pathlib import Path

import bwpass
from bundlewrap.metadata import atomic
from bundlewrap.utils import error_context

for node in Path(join(repo_path, "nodes")).rglob("*.py"):
    with error_context(filename=str(node)):
        with open(node, 'r') as f:
            exec(f.read())

for name, data in nodes.items():
    data.setdefault('hostname', '.'.join(reversed(name.split('.'))) + '.kunbox.net')
    data.setdefault('metadata', {}).setdefault('hostname', '.'.join(reversed(name.split('.'))) + '.kunbox.net')
