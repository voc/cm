#!/usr/bin/env python
# -*- coding: utf-8 -*-

from pydbus import SystemBus
from gi.repository import GLib
import collectd
import re
import time

DBUS_SYSTEMD = '.systemd1'

class NoSuchUnitException(Exception):
    pass

class SystemdCollector:
    """
    Collector class to collect statistics about systemd units
    """

    def __init__(self):
        self.__monitored_units = []
        self.__monitored_regexes = []

        self.__dbus = SystemBus()
        self.__systemd = self.__dbus.get(DBUS_SYSTEMD)

    def add_unit(self, unit):
        """
        add unit to scraping

        :param unit: str name of a systemd unit
        """
        try:
            unit_path = self.__systemd.GetUnit(unit)
            if unit_path not in self.__monitored_units:
                self.__monitored_units.append(unit_path)
        except GLib.Error as e:
            if 'NoSuchUnit' in e.message:
                raise NoSuchUnit('No Such Unit {}'.format(unit))
    
    def add_units_regex(self, regex):
        """
        add all units to scraping, which names match the regex

        :param regex: str regex
        """
        if regex not in self.__monitored_regexes:
            self.__monitored_regexes.append(regex)

    def collectd_config_callback(self, config):
        """
        collectd plugin api compatile configuration callback

        :param config: str configuration key
        """
        for sub_conf in config.children:
            if sub_conf.key == 'UnitName':
                self.add_unit(sub_conf.values[0])
            elif sub_conf.key == 'UnitRegex':
                self.add_units_regex(sub_conf.values[0])

    def collect_unit_stats(self):
        units = []
        units.extend(self.__monitored_units)

        for unit_tuple in self.__systemd.ListUnits():
            for regex in self.__monitored_regexes:
                if re.match(regex, unit_tuple[0]) is not None:
                    try:
                        unit_path = self.__systemd.GetUnit(unit_tuple[0])
                        if unit_path not in units:
                            units.append(unit_path)
                    except GLib.Error:
                        pass

        stats = {}

        for unit_path in units:
            unit = self.__dbus.get(DBUS_SYSTEMD, unit_path)
            
            enabled = unit.UnitFileState == 'enabled'
            active = unit.ActiveState == 'active'

            uptime = int(time.time() * 1000000) - unit.ActiveEnterTimestamp if active else 0
            downtime = int(time.time() * 1000000) - unit.InactiveEnterTimestamp if not active else 0

            stats[unit.Id] = {
                    "enabled": 1 if enabled else 0,
                    "active": 1 if active else 0,
                    "uptime": uptime,
                    "downtime": downtime,
            }

        return stats
    
    def collectd_read_callback(self, data=None):
        """
        collectd compatible read callback
        """
        for unit_name, stats in self.collect_unit_stats().items():
            for stat_name, value in stats.items():
                vl = collectd.Values(plugin='systemd_units', type='gauge', type_instance="{}/{}".format(unit_name, stat_name), values=[value] )
                vl.dispatch()

try:
    collector = SystemdCollector()

    collectd.register_read(collector.collectd_read_callback)
    collectd.register_config(collector.collectd_config_callback)
except (ImportError, AttributeError):
    collector = SystemdCollector()

    collector.add_units_regex('transcode_(h264|vpx|audio)@[a-zA-Z0-9]{2,2}\.service')

    print(collector.collect_unit_stats())

