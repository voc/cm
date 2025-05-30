#!/bin/sh

# /etc/kernel/postinst.d/unattended-upgrades

case "$DPKG_MAINTSCRIPT_PACKAGE::$DPKG_MAINTSCRIPT_NAME" in
    linux-image-extra*::postrm)
        exit 0;;
esac

if [ -d /var/run ]; then
    touch /var/run/reboot-required
    if ! grep -q "^$DPKG_MAINTSCRIPT_PACKAGE$" /var/run/reboot-required.pkgs 2> /dev/null ; then
        echo "$DPKG_MAINTSCRIPT_PACKAGE" >> /var/run/reboot-required.pkgs
    fi
fi
