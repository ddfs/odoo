# -*- encoding: utf-8 -*-
from openerp.addons.web.http import request

class website(osv.osv):
    _inherit = 'website'

    def get_alternate_languages(self, cr, uid, ids, req=None, context=None):
        if req is None:
            req = request.httprequest

        uri = req.path
        if req.query_string:
            uri += '?' + req.query_string

        langs = []
        shorts = []

        default = self.get_current_website(cr, uid, context=context).default_lang_code

        for code, name in self.get_languages(cr, uid, ids, context=context):
            lg_path = ('/' + code) if code != default else ''
            lg = code.split('_')

            shorts.append(lg[0])

            hreflang = ('-'.join(lg))
            short = lg[0]

            if default.lower() == code.lower():
                hreflang = short = "x-default"

            lang = {
                'hreflang': hreflang.lower(),
                'short': short.lower(),
                'href': req.url_root[0:-1] + lg_path + uri,
            }

            langs.append(lang)

        # use short language code. needed ??
        # should consider: fr-CA, fr-BE ??
        for lang in langs:
            if shorts.count(lang['short']) == 1:
                lang['hreflang'] = lang['short']

        return langs
