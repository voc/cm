#!/usr/bin/env python3

import logging
import os

from argparse import ArgumentParser
from paramiko.client import SSHClient, AutoAddPolicy, SSHException
from paramiko.ssh_exception import NoValidConnectionsError
from socket import timeout, gaierror, getaddrinfo


log = logging.getLogger(__file__)


def configure_logging(args):
    verbosity = (args.verbose or 0) - (args.quiet or 0)
    if verbosity <= -2:
        level = logging.CRITICAL
    elif verbosity == -1:
        level = logging.ERROR
    elif verbosity == 0:
        level = logging.WARNING
    elif verbosity == 1:
        level = logging.INFO
    elif verbosity >= 2:
        level = logging.DEBUG

    # fancy colors
    logging.addLevelName(logging.CRITICAL, '\033[1;41m%s\033[1;0m' % logging.getLevelName(logging.CRITICAL))
    logging.addLevelName(logging.ERROR, '\033[1;31m%s\033[1;0m' % logging.getLevelName(logging.ERROR))
    logging.addLevelName(logging.WARNING, '\033[1;33m%s\033[1;0m' % logging.getLevelName(logging.WARNING))
    logging.addLevelName(logging.INFO, '\033[1;32m%s\033[1;0m' % logging.getLevelName(logging.INFO))
    logging.addLevelName(logging.DEBUG, '\033[1;34m%s\033[1;0m' % logging.getLevelName(logging.DEBUG))

    if args.debug:
        log_format = '%(asctime)s - %(name)s - %(levelname)s {%(filename)s:%(lineno)d} %(message)s'
    else:
        log_format = '%(asctime)s - %(levelname)s - %(message)s'

    logging.basicConfig(filename=args.logfile, level=level, format=log_format)


def parse_ansible_inventory(filename: str):
    res = set()

    with open(filename, 'r') as f:
        lines = f.readlines()

    for line in lines:
        if line.startswith('#'):
            continue
        try:
            hostname = line.split()[0]
            if '[' in hostname:
                continue
            if hostname.endswith('.c3voc.de'):
                res |= {hostname}
        except IndexError:
            continue

    return res


def connect_host(client, hostname):
    log.info(f'Getting addresses for {hostname}')

    try:
        targets = {hostname} | \
                  {addrinfo[-1][0] for addrinfo in getaddrinfo(hostname, port=None)}
    except gaierror:
        log.warning(f'Cannot resolve {hostname}')
        return

    for target in targets:
        try:
            log.info(f'trying {target}')
            client.connect(target, timeout=1)
            client.close()
            log.info(f'{target} - Success')
        except SSHException:
            log.warning(f'{target} - SSHException')
        except NoValidConnectionsError:
            log.warning(f'{target} - NoValidConnectionsError')
        except timeout:
            log.warning(f'{target} - timeout')
        except OSError:
            log.warning('Cannot connect to network, check IPv6.')


def main():
    ap = ArgumentParser()
    ap.add_argument('--verbose', '-v', action='count')
    ap.add_argument('--quiet', '-q', action='count')
    ap.add_argument('--logfile', '-l')
    ap.add_argument('--debug', '-d', action='store_true')
    ap.add_argument('--outfile', '-o', default='/tmp/known_hosts')
    args = ap.parse_args()

    configure_logging(args)

    ansible_path = os.path.realpath(os.path.join(os.path.dirname(__file__), '..', 'ansible'))

    hosts = set()
    for inventory in ['event', 'relays', 'media']:
        filename = os.path.join(ansible_path, inventory)
        hosts |= parse_ansible_inventory(filename)

    client = SSHClient()
    client.set_missing_host_key_policy(AutoAddPolicy())

    for host in sorted(hosts):
        connect_host(client, host)

    client.save_host_keys(args.outfile)


if __name__ == "__main__":
    main()
