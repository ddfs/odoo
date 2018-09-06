#!/usr/bin/env python
# -*- encoding: utf-8 -*-
"""Uninstall a module"""

""" 
original gist code at: https://gist.github.com/repodevs/9fd47c5314a5074af9aafa2fddf4cb7b

this has minor updates to connect and handle multiple uninstallations
"""

import xmlrpclib
import argparse

parser = argparse.ArgumentParser()
# Connection args
parser.add_argument('-d', '--database', help="Database name to connect", action='store', metavar='DB', default='odoo')
parser.add_argument('-u', '--user', help="Odoo admin", action='store', metavar='USER', default='admin')
parser.add_argument('-w', '--password', help="Odoo password.", action='store', metavar='PASSWORD', default='admin')
parser.add_argument('-s', '--url', help="URL to connect", action='store', metavar='URL',
                    default='http://localhost:8069')
# Feature args
parser.add_argument('module', help="MODULE to uninstall", action='store', metavar='MODULE')

args = parser.parse_args()

# Log in
common = xmlrpclib.ServerProxy('{}/xmlrpc/2/common'.format(args.url))
uid = common.authenticate(args.database, args.user, args.password, {})

if not uid:
    print "Invalid credentials"
    exit(-1)

print "OK. UID: %s" % uid

# Get the object proxy
models = xmlrpclib.ServerProxy('{}/xmlrpc/2/object'.format(args.url))
print "OK."

# Search module
module_ids = models.execute_kw(args.database, uid, args.password,
                               'ir.module.module', 'search', [[['name', 'in', args.module.split(',')]]])

if not module_ids:
    print "Module not found."
    exit(1)

# Uninstall the module
print "OK. Uninstalling ID: %s" % module_ids

result = models.execute_kw(args.database, uid, args.password,
                           'ir.module.module', "button_immediate_uninstall", [module_ids])

if result and 'tag' in result and result['tag'] == 'reload':
    print "Done."
    exit(0)

# ./odoo_uninstall_module.py -s http://0.0.0.0:7769 -d odoo_database -u admin -w admin pos_notes
# or
# ./odoo_uninstall_module.py -s http://0.0.0.0:7769 -d odoo_database -u admin -w admin "pos_notes, website"
