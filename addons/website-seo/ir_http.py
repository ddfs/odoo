# -*- encoding: utf-8 -*-

import logging
import os
import werkzeug
import werkzeug.routing
import werkzeug.utils

from openerp.addons.website.models.ir_http import ir_http
from openerp.addons.website.models.website import url_for
from openerp.http import request
from openerp.tools import config

logger = logging.getLogger(__name__)


class ir_http(ir_http):
    _inherit = 'ir.http'

    def _dispatch(self):
        first_pass = not hasattr(request, 'website')
        request.website = None
        func = None
        try:
            func, arguments = self._find_handler()
            request.website_enabled = func.routing.get('website', False)
        except werkzeug.exceptions.NotFound:
            # either we have a language prefixed route, either a real 404
            # in all cases, website processes them
            request.website_enabled = True

        request.website_multilang = (
            request.website_enabled and
            func and func.routing.get('multilang', func.routing['type'] == 'http')
        )

        if 'geoip' not in request.session:
            record = {}
            if self.geo_ip_resolver is None:
                try:
                    import GeoIP
                    # updated database can be downloaded on MaxMind website
                    # http://dev.maxmind.com/geoip/legacy/install/city/
                    geofile = config.get('geoip_database')
                    if os.path.exists(geofile):
                        self.geo_ip_resolver = GeoIP.open(geofile, GeoIP.GEOIP_STANDARD)
                    else:
                        self.geo_ip_resolver = False
                        logger.warning('GeoIP database file %r does not exists', geofile)
                except ImportError:
                    self.geo_ip_resolver = False
            if self.geo_ip_resolver and request.httprequest.remote_addr:
                record = self.geo_ip_resolver.record_by_addr(request.httprequest.remote_addr) or {}
            request.session['geoip'] = record

        cook_lang = request.httprequest.cookies.get('website_lang')
        if request.website_enabled:
            try:
                if func:
                    self._authenticate(func.routing['auth'])
                else:
                    self._auth_method_public()
            except Exception as e:
                return self._handle_exception(e)

            request.redirect = lambda url, code=302: werkzeug.utils.redirect(url_for(url), code)
            request.website = request.registry['website'].get_current_website(request.cr, request.uid,
                                                                              context=request.context)
            langs = [lg[0] for lg in request.website.get_languages()]
            path = request.httprequest.path.split('/')
            if first_pass:
                nearest_lang = not func and self.get_nearest_lang(path[1])
                url_lang = nearest_lang and path[1]

                is_a_bot = self.is_a_bot()
                # force bots to scan only default language, not their preffered language
                if is_a_bot:
                    preferred_lang = request.website.default_lang_code
                else:
                    preferred_lang = ((cook_lang if cook_lang in langs else False)
                                      or self.get_nearest_lang(request.lang) or request.website.default_lang_code)

                request.lang = request.context['lang'] = nearest_lang or preferred_lang
                # if lang in url but not the displayed or default language --> change or remove
                # or no lang in url, and lang to dispay not the default language --> add lang
                # and not a POST request
                # and not a bot or bot but default lang in url
                if ((url_lang and (url_lang != request.lang or url_lang == request.website.default_lang_code))
                    or (
                                    not url_lang and request.website_multilang and request.lang != request.website.default_lang_code)
                    and request.httprequest.method != 'POST') \
                        and (not is_a_bot or (url_lang and url_lang == request.website.default_lang_code)):
                    if url_lang:
                        path.pop(1)
                    if request.lang != request.website.default_lang_code:
                        path.insert(1, request.lang)
                    path = '/'.join(path) or '/'
                    redirect = request.redirect(path + '?' + request.httprequest.query_string)
                    redirect.set_cookie('website_lang', request.lang)
                    return redirect
                elif url_lang:
                    path.pop(1)
                    return self.reroute('/'.join(path) or '/')
            # bind modified context
            request.website = request.website.with_context(request.context)
        resp = super(ir_http, self)._dispatch()
        if request.website_enabled and cook_lang != request.lang and hasattr(resp, 'set_cookie'):
            resp.set_cookie('website_lang', request.lang)
        return resp
