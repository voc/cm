#!/usr/bin/env python3

import json
import os
import logging
from sys import exit
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from subprocess import run

logging.basicConfig(level=logging.DEBUG)

LOG = logging.getLogger('loudness_info_updater')
BASE_DIR = '/opt/loudness-rendering'
DATA_DIR = f'{BASE_DIR}/data'

try:
    with open('/opt/voc/schedule.json') as f:
        schedule = json.load(f)
except (FileNotFoundError, json.decoder.JSONDecodeError):
    LOG.exception('could not load schedule')
    exit(0)

try:
    with open(f'{BASE_DIR}/config.json') as f:
        config = json.load(f)
except (FileNotFoundError, json.decoder.JSONDecodeError):
    LOG.exception('could not load config')
    exit(1)

rooms = {v['room']: k for k,v in config['streams'].items()}

TZ = ZoneInfo(schedule['schedule']['conference']['time_zone_name'])
LOG.debug(f'{TZ=}')
NOW = datetime.now(TZ)
LOG.info(f'{NOW=}')

room_info = {stream: None for stream in config['streams']}

for day in schedule['schedule']['conference']['days']:
    for room_name, room_talks in day['rooms'].items():
        if room_name not in rooms:
            LOG.debug(f'ignoring {room_name} because not configured')
            continue

        for talk in room_talks:
            talk['__start'] = datetime.strptime(talk['date'][:19], '%Y-%m-%dT%H:%M:%S').replace(tzinfo=TZ)
            d_h, d_m = talk['duration'].split(':')
            talk['__end'] = talk['__start'] + timedelta(hours=int(d_h), minutes=int(d_m))

            if talk['__start'] <= NOW < talk['__end']:
                room_info[rooms[room_name]] = talk
                break

for f in os.scandir(DATA_DIR):
    if (
        not f.name.startswith('.')
        and f.name not in room_info
    ):
        LOG.debug(f'deleting {f.name} because not configured')
        run(['rm', '-rf', os.path.join(DATA_DIR, f)])

for stream, talk in room_info.items():
    os.makedirs(os.path.join(DATA_DIR, stream), exist_ok=True)

    line2 = []
    if talk:
        if talk['do_not_record']:
            line2.append('OPTOUT')
        line2.append(talk['__start'].strftime('%H:%M'))
        line2.append(talk['__end'].strftime('%H:%M'))

    with open(os.path.join(DATA_DIR, stream, 'line1.txt.tmp'), 'w+') as f:
        if talk:
            f.write(talk['title'])
        else:
            f.write('')

    with open(os.path.join(DATA_DIR, stream, 'line2.txt.tmp'), 'w+') as f:
        f.write(' - '.join(line2))

    for i in ('line1', 'line2'):
        os.replace(
            os.path.join(DATA_DIR, stream, f'{i}.txt.tmp'),
            os.path.join(DATA_DIR, stream, f'{i}.txt'),
        )

    LOG.info(f'wrote info for {stream}')
