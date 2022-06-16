from os.path import join
from pathlib import Path

from bundlewrap.utils import error_context

import bwkeepass as keepass

groups = {}
for group in Path(join(repo_path, "groups")).rglob("*.py"):
    with error_context(filename=str(group)):
        with open(group, 'r') as f:
            exec(f.read())
