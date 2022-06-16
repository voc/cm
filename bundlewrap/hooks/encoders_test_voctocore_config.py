from bundlewrap.exceptions import BundleError
from re import match

def node_apply_start(repo, node, interactive=False, **kwargs):
    for sname, sconfig in node.metadata.get('voctocore/sources', {}).items():
        if not sname == 'slides' and not re.match(r'^cam[0-1]+$', sname):
            raise BundleError(f'{node.name}: voctocore source {sname} has invalid name, must be either "slides" or match "cam[0-9]+"')

        if not sconfig['devicenumber'].isdigit():
            raise BundleError(f'{node.name}: voctocore source {sname} has invalid device number {sconfig["devicenumber"]}')
