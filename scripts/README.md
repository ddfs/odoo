scripts
-------

- run-local.sh for development
- run-server.sh provives odoo instance as daemon for debian servers.

run-local.sh
------------
simple bash script for development environment. handles virtualenv, install and upgrading all or listed modules.
reset-view by ids supplied with username/password.

`$ ./run local` -> start odoo

`$ ./run env`   -> create virtualenv, install requirements and activate

`$ ./run clean` -> clean .pyc and __pycache__

`$ ./run install` -> install odoo database and stop

`$ ./run reset-view` -> user password view-id
