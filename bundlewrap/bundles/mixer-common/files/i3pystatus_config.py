from i3pystatus import Status

status = Status(
    logfile='/dev/null',
)

status.register("backlight",
    format="BACKLIGHT: {percentage}%",
    backlight="*",
    on_leftclick="sudo /usr/local/sbin/brightness full",
    on_rightclick="sudo /usr/local/sbin/brightness half",
    interval=1)

status.register("clock",
    format="%a, %Y-%m-%d %H:%M:%S (W%V)",)

status.register("battery",
    battery_ident="ALL",
    format="BATTERY: {status}{percentage:.2f}% {remaining:%E%h:%M}",
    status={
        "DIS": "↓",
        "CHR": "↑",
        "FULL": "",
    })

status.register("temp",
    format="CPU: {temp:.0f}°C",
    hints={"markup": "pango"},
    dynamic_color=True)

status.register("network",
    interface="eth0",
    format_up="{interface}:[ {v6cidr}][ {v4cidr}]",
    format_down="{interface}: down",
    divisor=1024,
    on_leftclick=None,
    on_rightclick=None,
    hints={"markup":"pango"})

status.run()
