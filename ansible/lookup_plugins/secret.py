from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import sys
import keepass

ENV = os.environ['ENV']

source = 'password' if ENV == 'test' else 'keepass'

''' 
Simple wrapper script, allowing to deploy this playbook for testing purpurses,
without needing access to the production keypass file
'''


class LookupModule(LookupBase):

    def run(self, terms, variables, **kwargs):
        
        if source == 'keepass':
            return 'keepass'

        ret = []
        for term in terms:
            path, attribute = term.rsplit('.', 1)
            print('beeing asked for secret: ' + path + ' ' + attribute)

            # TODO
            value = 'foo'

            ret.append(value)

        return ret

if __name__ == '__main__':

    module = None
    if source == 'keepass':
        module = keepass.LookupModule()
    else:
        module = LookupModule()

    if len(sys.argv) < 2:
        print('wrong number of arguments')
    else:
        print(module.run([sys.argv[1]], None)[0])

