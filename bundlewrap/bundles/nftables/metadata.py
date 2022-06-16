from bundlewrap.exceptions import BundleError

defaults = {
    'apt': {
        'packages': {
            'nftables': {},
        },
    },
}

@metadata_reactor.provides(
    'nftables/rules/99-port_rules',
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

            if proto not in {'udp'}:
                raise BundleError(f'firewall/port_rules: illegal identifier {portdef} in metadata for {node.name}')
        else:
            port = portdef
            proto = 'tcp'

        for target in targets:
            if port == '*' and target == '*':
                raise BundleError('firewall/port_rules: setting both port and target to * is unsupported')

            comment = f'comment "port_rules {target}"'

            if port != '*':
                if ':' in port:
                    parts = port.split(':')
                    port_str = f'{proto} dport {{ {parts[0]}-{parts[1]} }}'
                else:
                    port_str = f'{proto} dport {port}'
            else:
                port_str = f'meta l4proto {proto}'

            if target in ('ipv4', 'ipv6'):
                version_str = f'meta nfproto {target}'
            else:
                version_str = ''

            if target in ('*', 'ipv4', 'ipv6'):
                ruleset.add(f'inet filter input {version_str} {port_str} accept {comment}')
            else:
                resolved = repo.libs.tools.resolve_identifier(repo, target)

                for address in resolved['ipv4']:
                    ruleset.add(f'inet filter input meta nfproto ipv4 {port_str} ip saddr {address} accept {comment}')

                for address in resolved['ipv6']:
                    ruleset.add(f'inet filter input meta nfproto ipv6 {port_str} ip6 saddr {address} accept {comment}')

    return {
        'nftables': {
            'rules': {
                # order does not matter here.
                '99-port_rules': sorted(ruleset),
            },
        },
    }
