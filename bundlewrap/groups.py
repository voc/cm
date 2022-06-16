from os.path import join
from pathlib import Path

import bwkeepass as keepass

from bundlewrap.utils import error_context

for group in Path(join(repo_path, "groups")).rglob("*.py"):
    with error_context(filename=str(group)):
        with open(group, 'r') as f:
            exec(f.read())
