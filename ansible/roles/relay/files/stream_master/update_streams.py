#!/usr/bin/env python3
import os
import json
import tempfile
import re
import urllib.request
import time
import stat
from urllib.error import URLError
from collections import namedtuple

# Map Icecast stream source
def map_icecast(source, backend):
    url = source["listenurl"]
    return url.split("/")[-1]

# Get streams from icecast2
def fetch_icecast(backend):
    sources = []
    url = f"http://{backend['address']}/status-json.xsl"

    try:
        f = urllib.request.urlopen(url)
        result = json.load(f)["icestats"]

        # check whether streams exist at all
        if not "source" in result:
            return []

        # one stream
        if isinstance(result["source"], dict):
            sources.append(result["source"])

        # multiple streams
        elif isinstance(result["source"], list):
            sources = result["source"]

        #print("icecast", url, streams, "\n")
        sources = [map_icecast(source, backend) for source in sources]

    except URLError:
        print("Error: Could not fetch from", url)
        return []

    return sources

# select transcoder for a stream
# prefer empty transcoders
# if a stream is explicitely allowed on some transcoders, stick to them
def find_transcoder(key, transcoders, state):
    print("find transcoder for", key)
    explicit = False
    selected = None
    selected_load = 1
    for host in transcoders:
        transcoder = transcoders[host]
        load = (0.1 + transcoder["jobs"]) /  (0.1 + transcoder["capacity"])

        # stream matches explicit allow
        if "allow" in transcoder and key in transcoder["allow"]:
            # reset previous choice
            if not explicit:
                explicit = True
                selected = None
                selected_load = 1

            if load < 1 and load < selected_load:
                selected = transcoder
                selected_load = load

        # normal distribution
        elif not explicit and "allow" not in transcoder:
            if load < 1 and load < selected_load:
                selected = transcoder
                selected_load = load

    print("selected", selected)
    return selected

def find_stream(key, source, state):
    for stream in state["streams"]:
        if stream["key"] == key and stream["source"] == source:
            return stream
    return None

def update_state(state, conf):
    regex = re.compile(conf["stream-match"])
    valid_stream = lambda s: regex.match(s) is not None

    # Setup dict for transcoder lookup
    transcoders = {}
    for transcoder in conf["transcoders"]:
        transcoders[transcoder["host"]] = transcoder
        transcoder["jobs"] = 0

    # Remove invalid assignments, count transcoder streams
    for stream in state["streams"]:
        if "transcoding" in stream:
            worker = stream["transcoding"]["worker"]
            if worker in transcoders:
                transcoders[worker]["jobs"] += 1
            else:
                del stream["transcoding"]

    # Assign new streams
    for backend in conf["backends"]:
        sources = filter(valid_stream, fetch_icecast(backend))

        # merge source info into streams
        for key in sources:
            stream = find_stream(key, backend["address"], state)
            if stream is None:
                stream = {
                    "key": key,
                    "source": backend["address"],
                }
                state["streams"].append(stream)

            stream["artwork"] = {
                "base": conf["artwork_base"]
            }

            if not "transcoding" in stream:
                t = find_transcoder(stream["key"], transcoders, state)
                if t:
                    stream["transcoding"] = {
                        "worker": t["host"],
                        "sink": conf["sink"]
                    }
                    t["jobs"] += 1

            stream["lastUpdated"] = int(time.time())

    # Remove old streams
    now = time.time()
    delete = []
    for stream in state["streams"]:
        if not "lastUpdated" in stream or stream["lastUpdated"] < now - conf["timeout"]:
            print(f"expire outdated stream '{stream['key']}'")
            delete.append(stream)

    for stream in delete:
        state["streams"].remove(stream)

    return state

# read old state
def read_state(path):
    try:
        with open(path, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return {"streams": []}

# write new state atomically
def write_state(state, path):
    with tempfile.NamedTemporaryFile("w", delete=False) as f:
        json.dump(state, f)
        tmp = f.name
    os.chmod(tmp, stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IROTH)
    os.replace(tmp, path)

def main():
    import argparse, toml
    parser = argparse.ArgumentParser(description="Dynamic stream transcoding assignments")
    parser.add_argument("file", help="state json to input/output from/to")
    parser.add_argument("conf", help="toml config")
    args = parser.parse_args()

    # Parse config
    with open(args.conf, "r") as f:
        conf = toml.load(f)

    # read, update, rewrite
    state = read_state(args.file)
    update_state(state, conf)
    write_state(state, args.file)


if __name__ == "__main__":
    main()
