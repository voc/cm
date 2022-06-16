from ipaddress import ip_address, ip_network, IPv4Address, IPv4Network

from bundlewrap.exceptions import NoSuchGroup, NoSuchNode, BundleError
from bundlewrap.utils.text import bold, red
from bundlewrap.utils.ui import io

def resolve_identifier(repo, identifier):
    """
    Try to resolve an identifier (group or node). Return a set of ip
    addresses valid for this identifier.
    """
    try:
        nodes = {repo.get_node(identifier)}
    except NoSuchNode:
        try:
            nodes = repo.nodes_in_group(identifier)
        except NoSuchGroup:
            try:
                ip = ip_network(identifier)

                if isinstance(ip, IPv4Network):
                    return {'ipv4': {ip}, 'ipv6': set()}
                else:
                    return {'ipv4': set(), 'ipv6': {ip}}
            except ValueError:
                try:
                    return repo.libs.firewall.named_networks[identifier]
                except KeyError:
                    raise BundleError(
                        f'libs.tools.resolve_identifier(): Could not resolve {identifier}'
                    )

    found_ips = set()
    for node in nodes:
        for interface, config in node.metadata.get('interfaces', {}).items():
            for ip in config.get('ips', set()):
                if '/' in ip:
                    found_ips.add(ip_address(ip.split('/')[0]))
                else:
                    found_ips.add(ip_address(ip))

        if node.metadata.get('external_ipv4', None):
            found_ips.add(ip_address(node.metadata.get('external_ipv4')))

        try:
            found_ips.add(ip_address(node.hostname))
        except ValueError:
            pass

    ip_dict = {
        'ipv4': set(),
        'ipv6': set(),
    }

    for ip in found_ips:
        if isinstance(ip, IPv4Address):
            ip_dict['ipv4'].add(ip)
        else:
            ip_dict['ipv6'].add(ip)

    return ip_dict


def remove_more_specific_subnets(input_subnets) -> list:
    final_subnets = []

    for subnet in sorted(input_subnets):
        source = ip_network(subnet)

        if not source in final_subnets:
            subnet_found = False

            for dest_subnet in final_subnets:
                if source.subnet_of(dest_subnet):
                    subnet_found = True

            if not subnet_found:
                final_subnets.append(source)

    out = []
    for net in final_subnets:
        out.append(str(net))

    return out
