#!/usr/bin/env python3
import os
import re
import sys
import dbus
import json
import tempfile
import time
from urllib.parse import urlparse
from http.client import HTTPConnection, HTTPSConnection
from base64 import b64encode

CONF_DIR = "/opt/transcoder/config"
UNIT_REGEXP = re.compile("^transcode@(.+)\.target$")

# Fetch json via http/s with optional basicauth
def fetch(url, user=None, password=None):
    u = urlparse(url)
    headers = {}
    if u.scheme == "https":
        c = HTTPSConnection(u.netloc)
    elif u.scheme == "http":
        c = HTTPConnection(u.netloc)
    else:
        print(f"Unknown scheme in url: {u.scheme}")

    if user is not None and password is not None:
        token = b64encode(f"{user}:{password}".encode()).decode("ascii")
        headers["Authorization"] = f"Basic {token}"

    c.request("GET", u.path, headers=headers)
    res = c.getresponse()
    if res.status != 200:
        print(f"Fetch failed: {res.status} {res.reason}")
        return

    data = None
    try:
        data = json.loads(res.read().decode())
    except json.decoder.JSONDecodeError as e:
        print("Invalid JSON format: ", e)

    return data


# get streams we are responsible for
def filter_streams(data, name):
    streams = data["streams"]
    ret = {}
    for stream in streams:
        if "transcoding" in stream and "worker" in stream["transcoding"] and stream["transcoding"]["worker"] == name:
            ret[stream["key"]] = stream
    return ret

def template_config(stream):
    res = f"""\
stream_key={stream["key"]}
transcoding_source={stream["source"]}
transcoding_sink={stream["transcoding"]["sink"]}
artwork_base={stream["artwork"]["base"]}
"""
    if "options" in stream:
        for (key, value) in stream["options"].items():
            res += f"{key}={value}"
    return res

def gen_config(stream):
    path = CONF_DIR

    conf = template_config(stream)
    path = os.path.join(CONF_DIR, stream["key"])

    # read and compare original config
    existing = ""
    try:
        with open(path, "r") as f:
            existing = f.read()
    except FileNotFoundError:
        pass

    # replace atomically if changed
    if existing != conf:
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write(conf)
            tmp = f.name
        os.replace(tmp, path)
        return True

    return False

def get_running():
    proxy = bus.get_object("org.freedesktop.NetworkManager",
                       "/org/freedesktop/NetworkManager/Devices/eth0")

def get_unitname(stream):
    return f"transcode@{stream['key']}.target"

def restart_task(stream, mng):
    unitname = get_unitname(stream)
    print("restart/enable", unitname)
    try:
        mng.RestartUnit(unitname, "replace",
            dbus_interface="org.freedesktop.systemd1.Manager")
        mng.EnableUnitFiles([unitname], False, True,
            dbus_interface="org.freedesktop.systemd1.Manager")
    except dbus.exceptions.DBusException as e:
        print("Failed to restart/enable", unitname, e)
        return False
    return True

def stop_task(stream, mng):
    unitname = get_unitname(stream)
    print("stop/disable", unitname)
    try:
        mng.DisableUnitFiles([unitname], False,
            dbus_interface="org.freedesktop.systemd1.Manager")
        mng.StopUnit(unitname, "replace",
            dbus_interface="org.freedesktop.systemd1.Manager")
    except dbus.exceptions.DBusException as e:
        print("Failed to stop/disable", unitname, e)
        return False
    return True

# bring transcoding to desired state
def sync_tasks(streams):
    bus = dbus.SystemBus()

    # get transcode units
    mng = bus.get_object("org.freedesktop.systemd1", "/org/freedesktop/systemd1")
    units = mng.ListUnits(dbus_interface="org.freedesktop.systemd1.Manager")
    old_streams = {}
    for unit in units:
        match = UNIT_REGEXP.match(unit[0])
        if match is not None:
            key = match[1]
            if key in streams:
                streams[key]["unit"] = unit
            else:
                old_streams[key] = {"key": key, "unit": unit}

    # place configs
    os.makedirs(CONF_DIR, exist_ok=True)
    for key in streams:
        stream = streams[key]
        didChange = gen_config(stream)
        if didChange:
            res = restart_task(stream, mng)
            # remove config file to allow retry
            if not res:
                os.unlink(f"{CONF_DIR}/{key}")

    # stop old and remove configs
    for key in old_streams:
        stream = old_streams[key]
        res = stop_task(stream, mng)
        # remove config file when service is gone
        if res:
            try:
                os.unlink(f"{CONF_DIR}/{key}")
            except FileNotFoundError:
                pass

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Fetch stream info and adapt local transcoding tasks")
    parser.add_argument("url", help="streaming info url")
    parser.add_argument("name", help="our transcoder name")
    parser.add_argument("-u", "--user", help="user for http basic-auth")
    parser.add_argument("-p", "--password", help="password for http basic-auth")
    args = parser.parse_args()

    data = fetch(args.url, args.user, args.password)
    if data is None:
        sys.exit(1)
    streams = filter_streams(data, args.name)
    sync_tasks(streams)

if __name__ == "__main__":
    main()

