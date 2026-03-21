bitfocus companion
==================

This bundle deploys [Bitfocus Companion](https://bitfocus.io/companion) on video encoders. 
The bundle opens port 8000 for remote control of companion. 
It deploys a default set of integrations with companion. 
A web interface Password as well as a websockets connection to OBS Studio get configured by passwords read from faults.

Required metadata can look like:
```
[metadata.bitfocus-companion]
version = 'v4.2.5'
restrict-to = ["voc-internal", "voc-vpn", "172.19.164.0/23"]
```
