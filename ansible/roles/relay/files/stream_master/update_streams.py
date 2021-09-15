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
    return {
        "key": url.split("/")[-1],
        "source": url,
    }

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

# Map Icecast stream source
def map_srtrelay(source, backend):
    name = source["name"]
    address = backend["relay"]
    return {
        "key": name,
        "source": f"srt://{address}?streamid=play/{name}",
    }

def fetch_srtrelay(backend):
    sources = []
    url = f"http://{backend['api']}/streams"

    try:
        f = urllib.request.urlopen(url)
        streams = json.load(f)
        sources = [map_srtrelay(stream, backend) for stream in streams]

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

def find_stream(key, state):
    for stream in state["streams"]:
        if stream["key"] == key:
            return stream
    return None

def update_state(state, conf):
    regex = re.compile(conf["stream-match"])
    valid_stream = lambda s: "key" in s and regex.match(s["key"]) is not None

    options = []
    if "options" in conf:
        for option in conf["options"]:
            options.append({
                "regex": re.compile(option["stream-match"]),
                "set": option["set"],
            })

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
        streams = []
        if backend["type"] == "icecast":
            streams = filter(valid_stream, fetch_icecast(backend))
        elif backend["type"] == "srtrelay":
            streams = filter(valid_stream, fetch_srtrelay(backend))
        else:
            print("invalid backend type", "type" in backend and backend["type"])

        # merge source info into streams
        for candidate in streams:
            key = candidate["key"]
            stream = find_stream(key, state)
            if stream is None:
                stream = candidate
                state["streams"].append(stream)

            stream["lastUpdated"] = int(time.time())
            stream["artwork"] = {
                "base": conf["artwork_base"]
            }

            # apply type options
            stream["options"] = {}
            for option in options:
                if option["regex"].match(key) is not None:
                    for key, val in option["set"].items():
                        stream["options"][key] = val

            if not "transcoding" in stream:
                t = find_transcoder(stream["key"], transcoders, state)
                if t is None:
                    print(f"No transcoder available for {stream['key']}, capacity reached")
                    continue

                stream["transcoding"] = {
                    "worker": t["host"],
                    "sink": conf["sink"]
                }
                t["jobs"] += 1

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
        json.dump(state, f, indent=2)
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
