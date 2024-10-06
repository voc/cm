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
os.makedirs(DATA_DIR, exist_ok=True)

try:
    with open('/opt/voc/schedule.json') as f:
        schedule = json.load(f)
except (FileNotFoundError, json.decoder.JSONDecodeError):
    LOG.exception('could not load schedule')
    exit(0)

try:
    with open(f'{BASE_DIR}/config.json') as f:
        CONFIG = json.load(f)
except (FileNotFoundError, json.decoder.JSONDecodeError):
    LOG.exception('could not load config')
    exit(1)

TZ = ZoneInfo(schedule['schedule']['conference']['time_zone_name'])
LOG.debug(f'{TZ=}')
NOW = datetime.now(TZ)
LOG.info(f'{NOW=}')

room_info = None

for day in schedule['schedule']['conference']['days']:
    for room_name, room_talks in day['rooms'].items():
        if room_name != CONFIG['room_name']:
            continue

        LOG.info(f'found my room!')
        for talk in room_talks:
            talk['__start'] = datetime.strptime(talk['date'][:19], '%Y-%m-%dT%H:%M:%S').replace(tzinfo=TZ)
            d_h, d_m = talk['duration'].split(':')
            talk['__end'] = talk['__start'] + timedelta(hours=int(d_h), minutes=int(d_m))

            if talk['__start'] <= NOW < talk['__end']:
                room_info = talk
                break

if room_info:
    line2 = []

    if talk['do_not_record']:
        line2.append('OPTOUT')
    line2.append(talk['__start'].strftime('%H:%M'))
    line2.append(talk['__end'].strftime('%H:%M'))

    with open(os.path.join(DATA_DIR, 'line1.txt.tmp'), 'w+') as f:
        f.write(talk['title'])

    with open(os.path.join(DATA_DIR, 'line2.txt.tmp'), 'w+') as f:
        f.write(' - '.join(line2))
else:
    with open(os.path.join(DATA_DIR, 'line1.txt.tmp'), 'w+') as f:
        f.write('')

    with open(os.path.join(DATA_DIR, 'line2.txt.tmp'), 'w+') as f:
        f.write('')

for i in ('line1', 'line2'):
    os.replace(
        os.path.join(DATA_DIR, f'{i}.txt.tmp'),
        os.path.join(DATA_DIR, f'{i}.txt'),
    )

LOG.info(f'wrote info')
