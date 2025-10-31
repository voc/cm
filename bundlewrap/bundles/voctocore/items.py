from bundlewrap.exceptions import BundleError
from os.path import join, isfile

KEYBOARD_SHORTCUTS = {
    # maps inputs to buttons, first for Channel A, second Channel B
    "cam1": ("F1", "1"),
    "cam2": ("F2", "2"),
    "cam3": ("F3", "3"),
    "slides": ("F4", "4"),
    # only one button for features and scenes
    "scene_fs": ("F5",),
    "scene_sbs": ("F6",),
    "scene_lec": ("F7",),
    "feature_mirror": ("F9",),
    "feature_43": ("F10",),
}

PLAYOUT_PORTS = {
    "stream": 15000,
    "program": 11000,
}

DEFAULT_BLINDER = {
    'kind': 'file',
    'location': '/opt/voc/share/pause.ts',
}

SHOULD_BE_RUNNING = node.metadata.get("voctocore/should_be_running", True)

voctomix_version = node.metadata.get("voctomix2/rev")
sources = node.metadata.get("voctocore/sources", {})
assert node.has_bundle("encoder-common")
assert node.has_bundle("voctomix2")

slides_port = 0
for idx, sname in enumerate(sorted(sources)):
    PLAYOUT_PORTS[sname] = 13000 + idx
    if sname == "slides":
        slides_port = 13000 + idx

overlay_mapping = []
for filename, title in sorted(node.metadata.get("event/overlay_mappings", {}).items()):
    overlay_mapping.append(f"{filename}.png|{title}")

presets = {}
preset_buttons = ["q", "w", "e", "r", "t", "z", "u", "i", "o", "p"]
preset_camera_sources = sorted(
    [source for source in sources.keys() if source.startswith("cam")]
)
# fullscreen sources
for source in sorted(sources.keys()):
    icon = None
    source_kind = sources[source]["kind"]

    if source == "slides":
        icon = "slides.svg"
    elif source.startswith("cam"):
        icon = "speaker.svg"
    elif source_kind == "alsa" or source_kind == "pa":
        continue
    presets[f"fs_{source}"] = {
        "name": source.upper(),
        "icon": icon,
    }
    try:
        presets[f"fs_{source}"]["key"] = preset_buttons.pop(0)
    except IndexError:
        pass

if 'slides' in sources and node.metadata.get('voctocore/enable_sbs_presets_with_slides'):
    for source in sorted(preset_camera_sources):
        icon = None
        source_kind = sources[source]["kind"]
        if source_kind == "alsa" or source_kind == "pa":
            continue

        presets[f"sbs_slides_{source}"] = {
            "name": f"{source.upper()}|SLIDES",
            "icon": "side-by-side.svg",
        }
        try:
            presets[f"sbs_slides_{source}"]["key"] = preset_buttons.pop(0)
        except IndexError:
            pass

if len(preset_camera_sources) > 2 and node.metadata.get(
    "voctocore/enable_sbs_presets_for_multi_camera"
):
    # We have a (atleast) three-camera setup. We assume last camera is
    # the wide shot, give operators side-by-side shots of every other
    # camera combination.
    my_cameras = preset_camera_sources.copy()
    my_cameras.pop()  # remove last camera from list
    for cam1 in my_cameras:
        for cam2 in my_cameras:
            if f"sbs_{cam2}_{cam1}" in presets or cam1 == cam2:
                continue

            presets[f"sbs_{cam1}_{cam2}"] = {
                "name": f"{cam1.upper()}|{cam2.upper()}",
                "icon": "side-by-side.svg",
            }
            try:
                presets[f"sbs_{cam1}_{cam2}"]["key"] = preset_buttons.pop(0)
            except IndexError:
                pass

if "slides" in sources:
    # Regular event setup, we have slides and one or more cameras. Give
    # operators presets for lecture mode with every camera.
    for source in preset_camera_sources:
        presets[f"lec_slides_{source}"] = {
            "name": f"{source.upper()}|SLIDES",
            "icon": "side-by-side-preview.svg",
        }
        try:
            presets[f"lec_slides_{source}"]["key"] = preset_buttons.pop(0)
        except IndexError:
            pass

### voctomix
files["/opt/voctomix2/voctocore-config.ini"] = {
    "content_type": "mako",
    "source": f"voctocore-config-by-version/{voctomix_version}.ini",
    "context": {
        "audio": node.metadata.get("voctocore/audio", {}),
        "blinder": node.metadata.get("voctocore/blinder", DEFAULT_BLINDER),
        "event": node.metadata.get("event/slug"),
        "has_schedule": node.metadata.get("event/schedule_json", ""),
        "keyboard_shortcuts": KEYBOARD_SHORTCUTS,
        "mirror_view": node.metadata.get("voctocore/mirror_view"),
        "overlay_mapping": overlay_mapping,
        "presets": presets,
        "programout_audiosink": node.metadata.get("voctocore/programout_audiosink"),
        "programout_enabled": node.metadata.get("voctocore/programout_enabled"),
        "programout_videosink": node.metadata.get("voctocore/programout_videosink"),
        "room_name": node.metadata.get("event/room_name", ""),
        "sources": sources,
        "vaapi_enabled": node.metadata.get("voctocore/vaapi"),
        "fps": node.metadata.get("voctocore/fps"),
    },
    "triggers": {
        "svc_systemd:voctomix2-voctocore:restart",
    },
}
files["/usr/local/lib/systemd/system/voctomix2-voctocore.service"] = {
    "triggers": {
        "action:systemd-reload",
        "svc_systemd:voctomix2-voctocore:restart",
    },
}
svc_systemd["voctomix2-voctocore"] = {
    "needs": {
        "file:/opt/voctomix2/voctocore-config.ini",
        "file:/usr/local/lib/systemd/system/voctomix2-voctocore.service",
        "git_deploy:/opt/voctomix2/release",
        "pkg_apt:",
    },
    "tags": {
        "causes-downtime",
    },
    "running": SHOULD_BE_RUNNING,
    "enabled": SHOULD_BE_RUNNING,
}


### Monitoring
files["/usr/local/sbin/check_system.d/check_recording.sh"] = {
    # will get executed automatically by bundle:mqtt-monitoring
    "mode": "0755",
    "content_type": "mako",
    "context": {
        "event": node.metadata.get("event"),
    },
}
files["/usr/local/sbin/check_system.d/check_recording.pl"] = {
    "mode": "0644",
}


## recording-sink
files["/opt/voctomix2/scripts/recording-sink.sh"] = {
    "content_type": "mako",
    "context": {
        "event": node.metadata.get("event"),
        "parallel_slide_recording": node.metadata.get(
            "voctocore/parallel_slide_recording"
        )
        and slides_port,
        "slides_port": slides_port,
    },
    "mode": "0755",
    "triggers": {
        "svc_systemd:voctomix2-recording-sink:restart",
    },
}
files["/usr/local/lib/systemd/system/voctomix2-recording-sink.service"] = {
    "triggers": {
        "action:systemd-reload",
        "svc_systemd:voctomix2-recording-sink:restart",
    },
}
svc_systemd["voctomix2-recording-sink"] = {
    "after": {
        "svc_systemd:voctomix2-voctocore",
    },
    "needs": {
        "file:/opt/voctomix2/scripts/recording-sink.sh",
        "file:/usr/local/lib/systemd/system/voctomix2-recording-sink.service",
        "pkg_apt:ffmpeg",
    },
    "tags": {
        "causes-downtime",
    },
    "running": None,  # get's auto-started by svc_systemd:voctomix2-voctocore
}

## streaming-sink
files["/opt/voctomix2/scripts/streaming-sink.sh"] = {
    "content_type": "mako",
    "context": {
        "translators_premixed": node.metadata.get("voctocore/translators_premixed"),
        "dynaudnorm": node.metadata.get("voctocore/streaming_use_dynaudnorm"),
        "endpoint": node.metadata.get("voctocore/streaming_endpoint"),
        "event": node.metadata.get("event"),
        "parallel_slide_streaming": node.metadata.get(
            "voctocore/parallel_slide_streaming"
        )
        and slides_port,
        "srt_publish": node.metadata.get("voctocore/srt_publish"),
        "vaapi_enabled": node.metadata.get("voctocore/vaapi"),
    },
    "mode": "0755",
    "triggers": {
        "svc_systemd:voctomix2-streaming-sink:restart",
    },
}
files["/usr/local/lib/systemd/system/voctomix2-streaming-sink.service"] = {
    "content_type": "mako",
    "context": {
        "auth_key": node.metadata.get("voctocore/streaming_auth_key"),
    },
    "cascade_skip": False,
    "triggers": {
        "action:systemd-reload",
        "svc_systemd:voctomix2-streaming-sink:restart",
    },
}
svc_systemd["voctomix2-streaming-sink"] = {
    "after": {
        "svc_systemd:voctomix2-voctocore",
    },
    "needs": {
        "file:/opt/voctomix2/scripts/streaming-sink.sh",
        "file:/usr/local/lib/systemd/system/voctomix2-streaming-sink.service",
        "pkg_apt:ffmpeg",
    },
    "tags": {
        "causes-downtime",
    },
    "running": None,  # get's auto-started by svc_systemd:voctomix2-voctocore
}

## streaming-sink
for pname, pdevice in node.metadata.get("voctocore/playout", {}).items():
    if pname not in PLAYOUT_PORTS:
        raise BundleError(
            f'{node.name} wants to use voctocore playout for {pname}, which does not exist. Valid choices: {",".join(sorted(PLAYOUT_PORTS))}'
        )

    files[f"/opt/voctomix2/scripts/playout_{pname}.sh"] = {
        "source": "decklink-playout.sh",
        "content_type": "mako",
        "context": {
            "device": pdevice,
            "port": PLAYOUT_PORTS[pname],
        },
        "mode": "0755",
        "triggers": {
            f"svc_systemd:voctomix2-playout-{pname}:restart",
        },
    }
    files[f"/usr/local/lib/systemd/system/voctomix2-playout-{pname}.service"] = {
        "source": "voctomix2-playout.service",
        "content_type": "mako",
        "context": {
            "pname": pname,
        },
        "triggers": {
            "action:systemd-reload",
            f"svc_systemd:voctomix2-playout-{pname}:restart",
        },
    }
    svc_systemd[f"voctomix2-playout-{pname}"] = {
        "after": {
            "svc_systemd:voctomix2-voctocore",
        },
        "needs": {
            f"file:/opt/voctomix2/scripts/playout_{pname}.sh",
            f"file:/usr/local/lib/systemd/system/voctomix2-playout-{pname}.service",
            "pkg_apt:ffmpeg",
        },
        "tags": {
            "causes-downtime",
        },
    }

for pname in PLAYOUT_PORTS:
    if pname in node.metadata.get("voctocore/playout", {}):
        continue

    actions[f"voctocore_stop-playout_{pname}"] = {
        "command": f"systemctl disable --now voctomix2-playout-{pname}",
        "unless": f"! systemctl is-active voctomix2-playout-{pname}",
        "before": {
            "directory:/usr/local/lib/systemd/system",
        },
    }
