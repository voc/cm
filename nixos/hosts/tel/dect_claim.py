import asyncio
import os
import re
import socket

from yate.ivr import YateIVR

SOUNDS_PATH = "/run/current-system/sw/share/sounds/yate"


async def main(ivr: YateIVR):
    caller_id = ivr.call_params.get("caller", "")
    caller_id = re.sub("[^\\d]", "", caller_id)
    called_id = ivr.call_params.get("called", "")
    called_id = re.sub("[^\\d]", "", called_id)

    await ivr.play_soundfile(
                             os.path.join(SOUNDS_PATH, "yintro.slin"),
                             complete=True)
    await asyncio.sleep(0.5)

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect(("localhost", 9437))
        s.recv(1024)
        s.sendall(f"claim {caller_id} {called_id}".encode('utf-8'))
        s.recv(1024)


app = YateIVR()
app.run(main)
