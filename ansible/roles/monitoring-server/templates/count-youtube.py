#!/usr/bin/env python3
import socket, time, argparse
from urllib.request import urlopen
from urllib.error import URLError

def send(host, port, msg):
    sock = socket.socket()
    sock.connect((host, port))
    sock.sendall(str.encode(message))
    sock.close()

def metric(path, value):
    return "{:} {:f} {:d}\n".format(path, float(value), int(time.time()))

# Parse args
parser = argparse.ArgumentParser()
parser.add_argument("--port", default=2003, help="Port on which to send carbon daemon data", type=int)
parser.add_argument("--host", default="0.0.0.0", help="Host running the carbon daemon")
parser.add_argument("yid", help="Youtube Video ID")
parser.add_argument("name", help="Metric prefix")
args = parser.parse_args()
timeout = 60

while True:
    # Query viewers
    url = "https://www.youtube.com/live_stats?v=" + args.yid

    try:
        value = int(urlopen(url).read())

    except URLError:
        print("Request failed, timeout: {:d}".format(timeout))
        time.sleep(timeout)
        timeout = int(timeout * 1.5)
        continue

    timeout = 60

    # Compose graphite message
    message = metric("youtube.youtube.users.{:}_youtube".format(args.name), value)

    # Send graphite message
    print("send", args.host, args.port, message, end="")
    send(args.host, args.port, message)
    time.sleep(timeout)
