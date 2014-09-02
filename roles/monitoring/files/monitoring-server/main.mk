# Put your host names here
monitoring_host="monitoring.lan.c3voc.de"

ipaddresses = {
  # grabber
  'grabber1.lan.c3voc.de' : '10.73.1.2',
  'grabber2.lan.c3voc.de' : '10.73.2.2',
  'grabber3.lan.c3voc.de' : '10.73.3.2',
  'grabber4.lan.c3voc.de' : '10.73.4.2',
  'grabber5.lan.c3voc.de' : '10.73.5.2',
  # encoder
  'encoder1.lan.c3voc.de' : '10.73.1.3',
  'encoder2.lan.c3voc.de' : '10.73.2.3',
  'encoder3.lan.c3voc.de' : '10.73.3.3',
  'encoder4.lan.c3voc.de' : '10.73.4.3',
  'encoder5.lan.c3voc.de' : '10.73.5.3',
  # mixer
  'mixer1.lan.c3voc.de' : '10.73.1.1',
  'mixer2.lan.c3voc.de' : '10.73.2.1',
  'mixer3.lan.c3voc.de' : '10.73.3.1',
  'mixer4.lan.c3voc.de' : '10.73.4.1',
  'mixer5.lan.c3voc.de' : '10.73.5.1',
  # infobeamer
  'infobeamer1.lan.c3voc.de' : '10.73.1.4',
  'infobeamer2.lan.c3voc.de' : '10.73.2.4',
  'infobeamer3.lan.c3voc.de' : '10.73.3.4',
  'infobeamer4.lan.c3voc.de' : '10.73.4.4',
  'infobeamer5.lan.c3voc.de' : '10.73.5.4',
  # switch
  'switch1.lan.c3voc.de' : '10.73.1.253',
  'switch2.lan.c3voc.de' : '10.73.2.253',
  'switch3.lan.c3voc.de' : '10.73.3.253',
  'switch4.lan.c3voc.de' : '10.73.4.253',
  'switch5.lan.c3voc.de' : '10.73.5.253',
  'switchrz.lan.c3voc.de' : '10.73.0.253',
  # server
  'node.lan.c3voc.de'     : '10.73.0.1',
  'storage.lan.c3voc.de'  : '10.73.0.2',
  #'sun.lan.c3voc.de'      : '10.73.0.3',
#  'todesencoder.lan.c3voc.de' : '10.73.0.4',
#  'usa.lan.c3voc.de'      : '10.73.0.5',
  'live.lan.c3voc.de'     : '10.73.0.6',
#  'switchrz.lan.c3voc.de' : '10.73.0.3',
  'monitoring.lan.c3voc.de' : '10.73.0.8',
  'router.lan.c3voc.de' : '10.73.0.254',
#  'brisky.lan.c3voc.de' : '10.73.0.11',
#  'ron.lan.c3voc.de' : '10.73.0.12',
#  'haltmal.lan.c3voc.de' : '10.73.0.13',
  # stream player
#  'player1.lan.c3voc.de' : '10.73.200.1',
#  'player2.lan.c3voc.de' : '10.73.200.2',
#  'player3.lan.c3voc.de' : '10.73.200.3',
#  'player4.lan.c3voc.de' : '10.73.200.4',
#  'player4.lan.c3voc.de' : '10.73.200.4',
#  'player5.lan.c3voc.de' : '10.73.200.5',
  # not our department
  'router.noc' : '217.9.109.193',
  'google.de' : '173.194.113.151',
}

all_hosts = [
  # server
  'node.lan.c3voc.de|hypervisor|pyhiscal|linux|debian|rz',
  # 'sun.lan.c3voc.de|hypervisor|pyhiscal|linux|debian|rz',
  'storage.lan.c3voc.de|pyhiscal|linux|debian|rz',
  # 'usa.lan.c3voc.de|pyhiscal|linux|debian|rz',
  'live.lan.c3voc.de|vm|linux|debian|rz',
  'monitoring.lan.c3voc.de|vm|linux|debian|rz',
  'router.lan.c3voc.de|vm|linux|debian|rz',
  # 'brisky.lan.c3voc.de|vm|linux|debian|rz|nossh',
  # 'ron.lan.c3voc.de|vm|linux|debian|rz|nossh',
  # 'haltmal.lan.c3voc.de|vm|linux|debian|rz|nossh',
  # grabber
  'grabber1.lan.c3voc.de|grabber|nossh|saal1',
  'grabber2.lan.c3voc.de|grabber|nossh|saal2',
  'grabber3.lan.c3voc.de|grabber|nossh|saal3',
  'grabber4.lan.c3voc.de|grabber|nossh|saal4',
  'grabber5.lan.c3voc.de|grabber|nossh|saal5',
  # encoder
  'encoder1.lan.c3voc.de|linux|encoder|debian|saal1|recording',
  'encoder2.lan.c3voc.de|linux|encoder|debian|saal2|recording',
  'encoder3.lan.c3voc.de|linux|encoder|debian|saal3|recording',
  'encoder4.lan.c3voc.de|linux|encoder|debian|saal4|recording',
  'encoder5.lan.c3voc.de|linux|encoder|debian|saal5|recording',
  # mixer
  'mixer1.lan.c3voc.de|linux|mixer|debian|saal1',
  'mixer2.lan.c3voc.de|linux|mixer|debian|saal2',
  'mixer3.lan.c3voc.de|linux|mixer|debian|saal3',
  'mixer4.lan.c3voc.de|linux|mixer|debian|saal4',
  'mixer5.lan.c3voc.de|linux|mixer|debian|saal5',
  # switch
  'switch1.lan.c3voc.de|switch|saal1|nossh',
  'switch2.lan.c3voc.de|switch|saal2|nossh',
  'switch3.lan.c3voc.de|switch|saal3|nossh',
  'switch4.lan.c3voc.de|switch|saal4|nossh',
  'switch5.lan.c3voc.de|switch|saal5|nossh',
  'switchrz.lan.c3voc.de|switch',
  # player
  # 'player1.lan.c3voc.de|player|nossh',
  # 'player2.lan.c3voc.de|player|nossh',
  # 'player3.lan.c3voc.de|player|nossh',
  # 'player4.lan.c3voc.de|player|nossh',
  # 'player5.lan.c3voc.de|player|nossh',
  # infobeamer
  'infobeamer1.lan.c3voc.de|saal1|infobeamer|nossh',
  'infobeamer2.lan.c3voc.de|saal2|infobeamer|nossh',
  'infobeamer3.lan.c3voc.de|saal3|infobeamer|nossh',
  'infobeamer4.lan.c3voc.de|saal4|infobeamer|nossh',
  'infobeamer5.lan.c3voc.de|saal5|infobeamer|nossh',
  # not our department
  'router.noc|noc|router|nossh',
  #
  'google.de|nossh',
]

parents = [
  ( "router.noc", [ "google.de" ], ALL_HOSTS ),
  ( "switch1.lan.c3voc.de", [ "saal1", "!switch" ], ALL_HOSTS ),
  ( "switch2.lan.c3voc.de", [ "saal2", "!switch" ], ALL_HOSTS ),
  ( "switch3.lan.c3voc.de", [ "saal3", "!switch" ], ALL_HOSTS ),
  ( "switch4.lan.c3voc.de", [ "saal4", "!switch" ], ALL_HOSTS ),
  ( "switch5.lan.c3voc.de", [ "saal5", "!switch" ], ALL_HOSTS ),
  ( "node.lan.c3voc.de", [ "live.lan.c3voc.de", "monitoring.lan.c3voc.de", "router.lan.c3voc.de" ] ),
]

service_dependencies = [
 # ( "proc_nginx", ALL_HOSTS, [ "HTTP (.*) streaming website", "RTMP (.*)" ] ),
]


datasource_programs = [
 ( "ssh -l check-mk -i /var/lib/icinga/id_rsa <IP> 'sudo /usr/bin/check_mk_agent'", [ '!nossh', "!localhost" ], ALL_HOSTS ),
]

www_group = 'nagios'

filesystem_default_levels["magic"] = 0.8


extra_service_conf["max_check_attempts"] = [
  ( "2", ALL_HOSTS, ALL_SERVICES )
]


extra_service_conf ["normal_check_interval"] = [
  ( "120", ALL_HOSTS, ["DNS:*"] ),
]


check_parameters += [
 ( { "levels" : (90, 95.0)}, [ "koeln.media.ccc.de" ], [ "fs_/srv/libvirt/brain/rootfs" ] ),
 ( { "levels" : (85, 90.0)}, ALL_HOSTS, [ "fs_/boot" ] ),
 ( ( 10, 200.0, 500.0), ALL_HOSTS, [ "NTP Time" ] ),
]

inventory_processes = [
  # if we find a /usr/sbin/ntpd on any host => monitor it
  ( "ntpd", "/usr/sbin/ntpd", 'ntp', 1, 1, 1, 1),
  ( "ntpd", "/usr/sbin/ntpd", 'root', 1, 1, 1, 1), # openntp
  ( "sshd", "~.*sshd$", "root", 1, 1, 1, 1),
  ( "sshd-Spaces", "~.*-f\s/etc/ssh-spaces/sshd_config$", "root", 1, 1, 1, 1),
  ( "libvirtd", "~.*libvirtd\s-d$", "root", 1, 1, 1, 1),
  ( "radvd", "~.*radvd", "radvd", 1, 1, 1, 1),
  ( "dnsmasq", "/usr/sbin/dnsmasq", "dnsmasq", 1, 1, 1, 1),
  ( "nginx", "~.*nginx", "root", 1, 1, 1, 1),
  ( "openvpn", "/usr/sbin/openvpn", "root", 1, 1, 1, 1),
  ( "icecast2-beta", "/usr/bin/icecast2-beta", ANY_USER, 1, 1, 1, 1),
]

ntp_default_levels = (3, 10.0, 20.0)

if_inventory_uses_description = True
ignored_services += [
  # ignore kvm virtual interfaces
  ( ALL_HOSTS, [ "Interface .*vnet.*" ] ),
  # ignore openvpn interface
  ( ALL_HOSTS, [ "Interface .*tun.*" ] ),
  # ignore br-nat interface
  ( ALL_HOSTS, [ "Interface .*br-nat.*" ] ),
  # ignore br0ken check_mk megacli checks
  ( [ "storage.voc" ], [ "RAID Adapter.*" ]),
  # ignore not installed second cpu sensor
  ( [ "storage.lan.c3voc.de"], ALL_HOSTS, [ "IPMI Sensor Temperature_CPU2_Temp"] ),
]



extra_nagios_conf += r"""
# ARG1: URL to get
define command {
    command_name    check_https_certificate
    command_line    $USER1$/check_http -I $HOSTADDRESS$ -H $ARG1$ --sni -C 14
}

# check https default host
define command {
    command_name    check_https_default
    command_line    $USER1$/check_http -N -I $HOSTADDRESS$ -e "403,400" -S
}
# check https vhost
define command {
    command_name    check_https_vhost
    command_line    $USER1$/check_http -N -I $HOSTADDRESS$ -H $ARG1$ -S
}

# check http vhost
define command {
    command_name    check_http_vhost
    command_line    $USER1$/check_http -N -I $HOSTADDRESS$ -H $ARG1$
}

define command {
    command_name    check_http_streaming_frontend
    command_line    $USER1$/check_http -I $HOSTADDRESS$
}

define command {
    command_name    check_http_streaming_frontend6
    command_line    $USER1$/check_http -I $HOSTADDRESS6$
}

define command {
    command_name    check_http6
    command_line    $USER1$/check_http -N -6 -H $ARG1$
}

# check media mime types
define command {
    command_name    check_video_mime_types
    command_line    $USER1$/check_video_mime_types -b $ARG1$
}

# check ping6
define command {
    command_name    check_ping6
    command_line    $USER1$/check_ping -6 -H $HOSTNAME$ -w 150.0,20% -c 500.0,60% -p 5
}

# dns
define command {
    command_name    check_dns
    command_line    $USER1$/check_dns -H $ARG1$ -s $ARG2$ -a $ARG3$
}

# rtmp
define command {
    command_name    check_rtmp
    command_line    $USER1$/check_rtmp -r rtmp://$HOSTADDRESS$:1935/stream/$ARG1$ --width $ARG2$ --height $ARG3$
}

# icecast mount
define command {
    command_name    check_icecast_mount
    command_line    $USER1$/check_http -I $HOSTADDRESS6$ -p 8000 -u /$ARG1$ -N
}
"""

legacy_checks = [
#  (( "check_https_certificate!voc.media.ccc.de", "Certificate voc.media.ccc.de", True), [ "mng.berlin.voc.media.ccc.de" ] ),

# FIXME: disabled for 30c3
#  (( "check_dns!voc.media.ccc.de!ns1.koeln.ccc.de!195.54.164.163", "DNS: voc.media.ccc.de - ns1.koeln.ccc.de", True), [ "mng.berlin.voc.media.ccc.de" ] ),
#  (( "check_dns!voc.media.ccc.de!ns1.manno.name!195.54.164.163", "DNS: voc.media.ccc.de - ns1.manno.name", True), [ "mng.berlin.voc.media.ccc.de" ] ),
#  (( "check_dns!voc.media.ccc.de!8.8.8.8!195.54.164.163", "DNS: voc.media.ccc.de - 8.8.8.8", True), [ "mng.berlin.voc.media.ccc.de" ] ),
#  (( "check_dns!streaming.media.ccc.de!ns1.koeln.ccc.de!195.54.164.164", "DNS: streaming.media.ccc.de - ns1.koeln.ccc.de", True), [ "mng.berlin.voc.media.ccc.de" ] ),
#  (( "check_dns!streaming.media.ccc.de!ns1.manno.name!195.54.164.164", "DNS: streaming.media.ccc.de - ns1.manno.name", True), [ "mng.berlin.voc.media.ccc.de" ] ),
#  (( "check_dns!streaming.media.ccc.de!8.8.8.8!195.54.164.164", "DNS: streaming.media.ccc.de - 8.8.8.8", True), [ "mng.berlin.voc.media.ccc.de" ] ),
]


define_contactgroups = True
define_contactgroups = {
    "voc" : "Winkekatzen Operators",
}

# Create all needed host groups
define_hostgroups = True

# Alternative: define aliases for some host groups
define_hostgroups = {
  "saal1" : "HS1",
  "saal2" : "HS3",
  "saal3" : "HS4",
  "saal4" : "HS5",
  "saal5" : "HS6",
  "rz" : "Event RZ",
}

host_groups = [
 # Put all hosts with the tag 'muc' into the host group muc
 ( "saal1", ["saal1"], ALL_HOSTS ),
 ( "saal2", ["saal2"], ALL_HOSTS ),
 ( "saal3", ["saal3"], ALL_HOSTS ),
 ( "saal4", ["saal4"], ALL_HOSTS ),
 ( "saal5", ["saal5"], ALL_HOSTS ),
 ( "RZ",    ["rz"], ALL_HOSTS ),
]
