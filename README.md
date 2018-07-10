Odoo / OpenERP customizations
=============================
All changes made in modules included in their folders. 

Only modified is included. no __init__ or __openerp__ files here.

Each version has own folder, no seperate tags or branches


run
---
simple bash script for development environment. handles virtualenv, install and upgrading all or listed modules.

`$ ./run local` -> start odoo

`$ ./run env`   -> create virtualenv, install requirements and activate

`$ ./run clean` -> clean .pyc and __pycache__

`$ ./run install` -> install odoo database and stop
