from bundlewrap.exceptions import BundleError

defaults = {
    'apt': {
        'packages': {
            'nftables': {},
        },
    },
}


@metadata_reactor.provides(
    'nftables/input/99-port_rules',
)
def port_rules_to_nftables(metadata):
    # Using this, bundles can simply set up port based rules. This
    # reactor will then take care of converting those rules to actual
    # nftables rules
    ruleset = set()

    # Plese note we do not set any defaults for ports. Bundles are
    # expected to know themselves which default to use.
    for portdef, targets in metadata.get('firewall/port_rules', {}).items():
        if '/' in portdef:
            port, proto = portdef.split('/', 2)

            if proto not in ('tcp', 'udp'):
                raise BundleError(f'firewall/port_rules: illegal identifier {portdef} in metadata for {node.name}')
        else:
            port = portdef
            proto = None

        for target in targets:
            if (
                (port == '*' and target == '*')
                or (target == '*' and proto is None)
                or (port != '*' and proto is None)
            ):
                raise BundleError(f'firewall/port_rules: illegal combination of port, target and protocol: "{port}" "{target}" "{proto}"')

            comment = f'comment "port_rules {target}"'

            if port != '*':
                if ':' in port:
                    parts = port.split(':')
                    port_str = f'{proto} dport {{ {parts[0]}-{parts[1]} }} '
                else:
                    port_str = f'{proto} dport {port} '
            elif proto is not None:
                port_str = f'meta l4proto {proto} '
            else:
                port_str = ''

            if target == '*':
                ruleset.add(f'{port_str}accept {comment}')
            else:
                resolved = repo.libs.tools.resolve_identifier(repo, target)

                for address in resolved['ipv4']:
                    ruleset.add(f'{port_str}ip saddr {address} accept {comment}')

                for address in resolved['ipv6']:
                    ruleset.add(f'{port_str}ip6 saddr {address} accept {comment}')

    return {
        'nftables': {
            'input': {
                # order does not matter here.
                '99-port_rules': sorted(ruleset),
            },
        },
    }
