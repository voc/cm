from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import sys
import getpass

reload(sys)
sys.setdefaultencoding('UTF8')

from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase

try:
	from pykeepass import PyKeePass
except ImportError:
	raise AnsibleError(
		"pykeepass is missing - install with pip"\
		"(preferably into an virtualenv)"
	)

SAVED_PASSWORD = None

class LookupModule(LookupBase):
	FILENAME_ENV='KEEPASS'
	PASSWORD_ENV='KEEPASS_PW'

	password = None

	def run(self, terms, variables, **kwargs):
		filename = self.get_filename()
		password = self.get_password()

		ret = []
		kp = PyKeePass(filename, password)
		for term in terms:
			path, attribute = term.rsplit('.', 1)
			found = kp.find_entries_by_path(path, first=True)

			if not found:
				raise AnsibleError(
						"Entry %s not found in keepass-Database %s" % \
						(path, filename)
					)

			if attribute.startswith('attr_'):
				dict = found.custom_properties
				value = dict[attribute[len('attr_'):]]
			else:
				value = getattr(found, attribute)

			ret.append(value)

		return ret

	def get_filename(self):
		filename = os.environ.get(LookupModule.FILENAME_ENV)

		if not filename:
			raise AnsibleError(
					"Environment-Variable %s not set" % \
					(LookupModule.FILENAME_ENV)
				)

		return filename

	def get_password(self):
		password = os.environ.get(LookupModule.PASSWORD_ENV)

		if not password:
			raise AnsibleError(
					"Environment-Variable %s not set" % \
					(LookupModule.PASSWORD_ENV)
				)

		return password

	def open_stdin(self):
		was_closed = sys.stdin.closed
		if was_closed:
			sys.stdin = open('/dev/tty')

		return was_closed

	def close_stdin(self):
		sys.stdin.close()

	def test_password(self, file, password):
		filename = self.get_filename()

		try:
			kp = PyKeePass(filename, password)
		except IOError:
			return False

		return True
