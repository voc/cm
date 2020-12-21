#!/usr/bin/env python3
import os
import argparse
import shlex
import subprocess
import sys

defines = {
    "icecast_password": "{{ lookup('keepass', 'ansible/icecast/icedist/source.password') }}",
}

def get_dri_devices():
    try:
        entries = os.listdir("/sys/kernel/debug/dri")
    except PermissionError:
        print("Not running with privileges, no hardware acceleration available")
        return []
    return entries


def get_vaapi_drivers(devicenum):
    try:
        with open(f"/sys/kernel/debug/dri/{devicenum}/name", "r") as f:
            res = f.read()
    except FileNotFoundError:
        return []

    driver = res.split(" ")[0]
    if driver == "i915":
        return ["iHD", "i965"]
    elif driver == "amdgpu":
        return ["radeonsi"]
    elif driver == "nouveau":
        return ["nouveau"]
    else:
        return []


def parse_vainfo(driver: str, device: str):
    """
    calls vainfo for a specific device and driver and returns a list of en/decoder
    :param driver: va driver name
    :param device: path of render device
    :return: list of en/decoder supported
    """
    env_vars = {"LIBVA_DRIVER_NAME": driver}
    os.environ.update(env_vars)
    try:
        vainfo = subprocess.check_output(["vainfo", "--display", "drm", "--device", device],
                                         stderr=subprocess.DEVNULL).decode().split("\n")
    except subprocess.CalledProcessError:
        return []
    except FileNotFoundError:
        print("vainfo was not found. Please install vainfo")
        return []

    features = []
    for line in vainfo:
        if line.strip().startswith("VA"):
            line = line.strip().replace(" ", "").replace("\t", "")
            if line == "VAProfileH264High:VAEntrypointEncSlice":
                features.append("h264-enc")
            elif line == "VAProfileVP9Profile0:VAEntrypointEncSlice":
                features.append("vp9-enc")
    return features


def vainfo():
    devnum = 128
    dev = f"/dev/dri/renderD{devnum}"
    for driver in ["iHD", "i965", "radeonsi", "nouveau"]:
        features = parse_vainfo(driver, dev)
        if len(features) > 0:
            return dev, driver, features
    return None, None, []


def check_arg(env, key, flag):
    if flag is not None:
        env[key] = flag
    if env[key] is None:
        print(f"Param {key} must be set")
        sys.exit(1)


def main():
    env = dict()
    env["stream"] = os.getenv("stream_key")
    env["source"] = os.getenv("transcoding_source")
    env["sink"] = os.getenv("transcoding_sink")
    env["type"] = os.getenv("type", "all")
    env["vaapi_dev"], env["vaapi_driver"], env["vaapi_features"] = vainfo()

    parser = argparse.ArgumentParser(description="Transcode voc stream")
    parser.add_argument("--stream", help="stream key")
    parser.add_argument("--source", help="transcoding input")
    parser.add_argument("--sink", help="transcoding sink host")
    parser.add_argument("--type", help="transcode type",
                        choices=["h264-only", "all"])
    parser.add_argument("-o", "--output", help="output type",
                        default="icecast", choices=["icecast", "null"])
    parser.add_argument("-progress", help="pass to ffmpeg progress")
    parser.add_argument("--vaapi-features", action="append",
                        help="override vaapi features")
    parser.add_argument("--vaapi-device", help="override vaapi device")
    parser.add_argument("-v", "--verbose", help="set verbosity",
                        default="warning")
    args = parser.parse_args()

    check_arg(env, "stream", args.stream)
    check_arg(env, "source", args.source)
    check_arg(env, "sink", args.sink)
    check_arg(env, "type", args.type)

    # handle external ffmpeg-progress
    progress = ""
    if args.progress is not None:
        print("using progress", args.progress)
        progress = f"-progress {args.progress}"

    if args.vaapi_device is not None:
        print("override vaapi device", args.vaapi_device)
        env["vaapi_dev"] = args.vaapi_device

    if args.vaapi_features is not None:
        print("override", args.vaapi_features)
        env["vaapi_features"] = args.vaapi_features

    print("using vaapi driver", env["vaapi_driver"])
    env_vars = {"LIBVA_DRIVER_NAME": env["vaapi_driver"]}
    os.environ.update(env_vars)

    # choose output
    output = output_icecast
    if args.output == "null":
        output = output_null

    # build arguments
    arguments = []
    if env["type"] == "h264-only":
        arguments = transcode_h264(env, output)
    else:
        arguments = transcode_all(env, output)

    arguments.insert(0, f"""/usr/bin/env ffmpeg -hide_banner -v {args.verbose} {progress} -nostdin -y
            -analyzeduration 50000000 -timeout 10000000""")
    call = shlex.split(" ".join(arguments))
    try:
        subprocess.check_call(call, stdout=sys.stdout, stderr=sys.stderr)
    except subprocess.CalledProcessError:
        # print(e)
        sys.exit(1)


def transcode_all(env, output):
    source = env["source"]
    stream = env["stream"]
    vaapi_dev = env["vaapi_dev"]
    vaapi_features = env["vaapi_features"]

    # all vaapi
    if vaapi_dev is not None and "vp9-enc" in vaapi_features:
        print("running all vaapi transcode")
        return [
            f"""
            -init_hw_device vaapi=transcode:{vaapi_dev}
            -hwaccel vaapi
            -hwaccel_output_format vaapi
            -hwaccel_device transcode
            -i {source}
            -filter_hw_device transcode
            -filter_complex "
                [0:v:0] split=3 [_hd1][_hd2][_hd3];
                [_hd2] hwdownload [hd_vp9];
                [_hd1] scale_vaapi=1024:576,split [sd_h264][sd_vp9];
                [_hd3] framestep=step=500,split [poster][_poster];
                [_poster] scale_vaapi=w=213:h=-1 [thumb]"
            """,
            encode_h264_vaapi(),
            output(env, f"{stream}_h264"),
            encode_vp9_vaapi(),
            output(env, f"{stream}_vpx"),
            encode_thumbs_vaapi(),
            output(env, f"{stream}_thumbnail"),
            encode_audio(),
            output(env, f"{stream}_audio"),
        ]

    # h264 + software vp9
    elif vaapi_dev is not None and "h264-enc" in vaapi_features:
        print("falling back to software transcode with software vp9")
        return [
            f"""
            -init_hw_device vaapi=transcode:{vaapi_dev}
            -hwaccel vaapi
            -hwaccel_output_format vaapi
            -hwaccel_device transcode
            -i {source}
            -filter_hw_device transcode
            -filter_complex "
                [0:v:0] split=3 [_hd1][_hd2][_hd3];
                [_hd2] hwdownload [hd_vp9];
                [_hd1] scale_vaapi=1024:576,split [sd_h264][_sd2];
                [_sd2] hwdownload [sd_vp9];
                [_hd3] framestep=step=500,split [poster][_poster];
                [_poster] scale_vaapi=w=213:h=-1 [thumb]"
            """,
            encode_h264_vaapi(),
            output(env, f"{stream}_h264"),
            encode_vp9_software(),
            output(env, f"{stream}_vpx"),
            encode_thumbs_vaapi(),
            output(env, f"{stream}_thumbnail"),
            encode_audio(),
            output(env, f"{stream}_audio"),
        ]

    # software
    else:
        print("falling back to software transcode")
        return [
            f"""
            -i {source}
            -filter_complex "
                [0:v:0] split [_hd1][_hd2];
                [_hd1] scale=1024:576,split [sd_h264][sd_vp9];
                [_hd2] framestep=step=500,split [poster][_poster];
                [_poster] scale=w=213:h=-1 [thumb]"
            """,
            encode_h264_software(),
            output(env, f"{stream}_h264"),
            encode_vp9_software("0:v:0"),
            output(env, f"{stream}_vpx"),
            encode_thumbs_software(),
            output(env, f"{stream}_thumbnail"),
            encode_audio(),
            output(env, f"{stream}_audio"),
        ]


def transcode_h264(env, output):
    source = env["source"]
    stream = env["stream"]
    vaapi_dev = env["vaapi_dev"]
    vaapi_features = env["vaapi_features"]

    # vaapi
    if vaapi_dev is not None and "h264-enc" in vaapi_features:
        return [
            f"""
            -init_hw_device vaapi=transcode:{vaapi_dev}
            -hwaccel vaapi
            -hwaccel_output_format vaapi
            -hwaccel_device transcode
            -i {source}
            -filter_hw_device transcode
            -filter_complex "
                [0:v:0] split [_hd1][_hd2];
                [_hd1] scale_vaapi=1024:576 [sd_h264];
                [_hd2] framestep=step=500,split [poster][_poster];
                [_poster] scale_vaapi=w=213:h=-1 [thumb]"
            """,
            encode_h264_vaapi(),
            output(env, f"{stream}_h264"),
            encode_thumbs_vaapi(),
            output(env, f"{stream}_thumbnail"),
            encode_audio(),
            output(env, f"{stream}_audio"),
        ]
    # software
    else:
        return [
            f"""
            -i {source}
            -filter_complex "
                [0:v:0] split [_hd1][_hd2];
                [_hd1] scale_vaapi=1024:576 [sd_h264];
                [_hd2] framestep=step=500,split [poster][_poster];
                [_poster] scale_vaapi=w=213:h=-1 [thumb]"
            """,
            encode_h264_software(),
            output(env, f"{stream}_h264"),
            encode_thumbs_software(),
            output(env, f"{stream}_thumbnail"),
            encode_audio(),
            output(env, f"{stream}_audio"),
        ]


##
# Codecs
##
def encode_h264_vaapi(hd_input="0:v:0", sd_input="[sd_h264]"):
    return f"""
    -map '{hd_input}'
        -metadata:s:v:0 title="HD"
        -c:v:0 h264_vaapi
            -r:v:0 25
            -keyint_min:v:0 75
            -g:v:0 75
            -b:v:0 2800k
            -bufsize:v:0 8400k
            -flags:v:0 +cgop

    -map '{sd_input}'
        -metadata:s:v:1 title="SD"
        -c:v:1 h264_vaapi
            -r:v:1 25
            -keyint_min:v:1 75
            -g:v:1 75
            -b:v:1 800k
            -bufsize:v:1 2400k
            -flags:v:1 +cgop

    -map '0:v:1?'
        -metadata:s:v:2 title="Slides"
        -c:v:2 copy

    -c:a aac -ac:a 2 -b:a 128k

    -map '0:a:0' -metadata:s:a:0 title="Native"
    -map '0:a:1?' -metadata:s:a:1 title="Translated"
    -map '0:a:2?' -metadata:s:a:2 title="Translated-2"
"""


def encode_h264_software(hd_input="0:v:0", sd_input="[sd_h264]"):
    return f"""
    -map '{hd_input}'
        -metadata:s:v:0 title="HD"
        -c:v:0 libx264
            -maxrate:v:0 2800k
            -crf:v:0 21
            -bufsize:v:0 5600k
            -pix_fmt:v:0 yuv420p
            -profile:v:0 main
            -r:v:0 25
            -keyint_min:v:0 75
            -g:v:0 75
            -flags:v:0 +cgop
            -preset:v:0 veryfast

    -map '{sd_input}'
        -metadata:s:v:1 title="SD"
        -c:v:1 libx264
            -maxrate:v:1 800k
            -crf:v:1 23
            -bufsize:v:1 3600k
            -pix_fmt:v:1 yuv420p
            -profile:v:1 main
            -r:v:1 25
            -keyint_min:v:1 75
            -g:v:1 75
            -flags:v:1 +cgop
            -preset:v:1 veryfast

    -map '0:v:1?'
        -metadata:s:v:2 title="Slides"
        -c:v:2 copy

    -c:a aac -ac:a 2 -b:a 128k

    -map '0:a:0' -metadata:s:a:0 title="Native"
    -map '0:a:1?' -metadata:s:a:1 title="Translated"
    -map '0:a:2?' -metadata:s:a:2 title="Translated-2"
"""


def encode_vp9_vaapi(hd_input="[hd_vp9]", sd_input="[sd_vp9]"):
    return f"""
    -map '{hd_input}'
        -metadata:s:v:0 title="HD"
        -c:v:0 libvpx-vp9
            -deadline:v:0 realtime
            -cpu-used:v:0 8
            -threads:v:0 6
            -frame-parallel:v:0 1
            -tile-columns:v:0 2

            -r:v:0 25
            -keyint_min:v:0 75
            -g:v:0 75
            -crf:v:0 23
            -row-mt:v:0 1
            -b:v:0 2800k -maxrate:v:0 2800k
            -bufsize:v:0 8400k

    -map '{sd_input}'
        -metadata:s:v:1 title="SD"
        -c:v:1 vp9_vaapi
            -r:v:1 25
            -keyint_min:v:1 75
            -g:v:1 75
            -b:v:1 800k
            -bufsize:v:1 2400k

    -map '0:v:1?'
        -metadata:s:v:2 title="Slides"
        -c:v:2 vp9_vaapi
            -keyint_min:v:2 15
            -g:v:2 15
            -b:v:2 100k
            -bufsize:v:2 750k

    -c:a libopus -ac:a 2 -b:a 128k
    -af "aresample=async=1:min_hard_comp=0.100000:first_pts=0"

    -map '0:a:0' -metadata:s:a:0 title="Native"
    -map '0:a:1?' -metadata:s:a:1 title="Translated"
    -map '0:a:2?' -metadata:s:a:2 title="Translated-2"
"""


def encode_vp9_software(hd_input="[hd_vp9]", sd_input="[sd_vp9]"):
    return f"""
        -c:v libvpx-vp9
        -deadline:v realtime -cpu-used:v 8
        -frame-parallel:v 1 -crf:v 23 -row-mt:v 1

    -map '{hd_input}'
        -metadata:s:v:0 title="HD"
        -threads:v:0 6
        -tile-columns:v:0 2
        -r:v:0 25
        -keyint_min:v:0 75
        -g:v:0 75
        -b:v:0 2800k -maxrate:v:0 2800k
        -bufsize:v:0 8400k

    -map '{sd_input}'
        -metadata:s:v:1 title="SD"
        -threads:v:1 6
        -tile-columns:v:1 2
        -r:v:1 25
        -keyint_min:v:1 75
        -g:v:1 75
        -b:v:1 800k -maxrate:v:1 800k
        -bufsize:v:1 2400k

    -map '0:v:1?'
        -metadata:s:v:2 title="Slides"
        -threads:v:2 4
        -tile-columns:v:2 1
        -keyint_min:v:2 15
        -g:v:2 15
        -b:v:2 100k -maxrate:v:2 100k
        -bufsize:v:2 750k

    -c:a libopus -ac:a 2 -b:a 128k
    -af "aresample=async=1:min_hard_comp=0.100000:first_pts=0"

    -map '0:a:0' -metadata:s:a:0 title="Native"
    -map '0:a:1?' -metadata:s:a:1 title="Translated"
    -map '0:a:2?' -metadata:s:a:2 title="Translated-2"
"""


def encode_thumbs_vaapi(poster_input="[poster]", thumb_input="[thumb]"):
    return f"""
    -c:v mjpeg_vaapi
    -map '{poster_input}'
        -metadata:s:v:0 title="Poster"
    -map '{thumb_input}'
        -metadata:s:v:1 title="Thumbnail"
    -an
"""


def encode_thumbs_software(poster_input="[poster]", thumb_input="[thumb]"):
    return f"""
    -c:v mjpeg -pix_fmt:v yuvj420p
    -map '{poster_input}'
        -metadata:s:v:0 title="Poster"
    -map '{thumb_input}'
        -metadata:s:v:1 title="Thumbnail"
    -an
"""


def encode_audio():
    return """
    -ac:a 2
    -map '0:a:0'
        -c:a:0 libmp3lame -b:a:0 128k
        -metadata:s:a:0 title="Native"

    -map '0:a:0'
        -c:a:1 libopus -vbr:a:1 off -b:a:1 128k
        -metadata:s:a:1 title="Native"

    -map '0:a:1?'
        -c:a:2 libmp3lame -b:a:2 128k
        -metadata:s:a:2 title="Translated"

    -map '0:a:1?'
        -c:a:3 libopus -vbr:a:3 off -b:a:3 128k
        -metadata:s:a:3 title="Translated"

    -map '0:a:2?'
        -c:a:4 libmp3lame -b:a:4 128k
        -metadata:s:a:4 title="Translated-2"

    -map '0:a:2?'
        -c:a:5 libopus -vbr:a:5 off -b:a:5 128k
        -metadata:s:a:5 title="Translated-2"
"""


def output_icecast(env, slug):
    return f"""
    -fflags +genpts
    -max_muxing_queue_size 400
    -f matroska
    -password {defines["icecast_password"]}
    -content_type video/webm
    "icecast://{env["sink"]}/{slug}"
"""


def output_null(env, slug):
    return "-max_muxing_queue_size 400 -f null -"


if __name__ == "__main__":
    main()
