RouterOS
========

Pulls device configuration from `configs/netbox_device_{NODENAME}.json` and creates items accordingly.

Notes
-----

To add management IPs to a VLAN, you need to create a virtual interface in Netbox whose name matches the name of a VLAN. Then add the IP to that virtual interface.
