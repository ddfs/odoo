# -*- coding: utf-8 -*-

import logging

from openerp.addons.web import http
from openerp.http import request
from openerp.addons.website.controllers.main import Website


logger = logging.getLogger(__name__)


class HxnWebsite(Website):
    @http.route("/website/info", type="http", auth="public", website=True)
    def website_info(self):
        # show 404
        logger.info("website.info is disabled")
        return request.website.render("website.404")
