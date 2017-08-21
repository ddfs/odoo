#!/bin/bash

#
# clean .pyc files
#
find . -name "*.pyc" -delete

#
# Full upgrade
#
# ./openerp-server --config=./etc/openerp-server.conf --xmlrpc-port=8090 --log-level=info --stop-after-init -u base -i base_ext

#
# Local run
#
# --email-from=portal@myportal.fi
# --load-language=fi_FI
# --auto-reload
# --debug
./openerp-server --config=./etc/openerp-server.conf --xmlrpc-port=8090 --log-level=info --without-demo=all \
-u base_ext \
-u account_ext \
-u mail_ext \
-u product_ext \
-u report_ext \
-u sale_ext \
-u sale_order_ext \
-u web_ext \
-u website_ext \
-u website_crm_ext \
-u website_sale_ext \
-u website_sale_delivery_ext
