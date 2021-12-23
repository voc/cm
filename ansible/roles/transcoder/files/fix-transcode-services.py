#!/usr/bin/env python3

import pystemd.systemd1
import consul
import socket
import sys
import time
sys.path.append("/opt/transcoder2/scripts")
import config
import mqtt

cons = consul.Consul()

def get_running_transcodings():
    manager = pystemd.systemd1.Manager()
    manager.load()
    transcodings = []
    for service in manager.Manager.ListUnitsByPatterns(["active"], ["transcode@*.service"]):
        transcodings.append(service[0].decode()[10:-8])
    return transcodings

def get_transcoder_for_stream(stream):
    kv = cons.kv.get('stream/%s/transcoder' % stream)[1]
    if not kv:
        return
    return kv['Value'].decode().split(".")[0]

def get_all_streams():
    kv = cons.kv.get("stream", keys=True)[1]
    if not kv:
        return []
    all_streams = []
    for stream in kv:
        stream = stream.split("/")
        if len(stream) == 3 and stream[2] == "transcoder":
            all_streams.append(stream[1])
    return all_streams

def fix_transcode_services():
    me = socket.gethostname()
    running = get_running_transcodings()
    for stream in running:
        transcoder = get_transcoder_for_stream(stream)
        if transcoder and me != transcoder:
            with mqtt.Client(True) as client:
                client.info("Uh oh, I shouldn't be encoding %s... stopping target..." % stream)
            time.sleep(1)
            target = pystemd.systemd1.Unit("transcode@%s.target" % stream)
            target.load()
            target.Unit.Stop(b'replace')

    for stream in get_all_streams():
        transcoder = get_transcoder_for_stream(stream)
        if transcoder and me == transcoder and stream not in running:
            with mqtt.Client(True) as client:
                client.info("Uh oh, I should be encoding %s... starting target..." % stream)
            time.sleep(1)
            target = pystemd.systemd1.Unit("transcode@%s.target" % stream)
            target.load()
            target.Unit.Start(b'replace')

def main():
    while True:
        fix_transcode_services()
        time.sleep(10)

if __name__ == '__main__':
    main()
