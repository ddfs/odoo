from openerp.osv import fields, osv

class Website(osv.osv):
    _inherit = 'website'

    _columns = {
        'exclude_from_sitemap': fields.text('Exclude from sitemap')
    }


class WebsiteConfigSettings(osv.osv_memory):
    _inherit = 'website.config.settings'

    _columns = {
        'exclude_from_sitemap': fields.related('website_id', 'exclude_from_sitemap', type="text",
                                               string='Exclude from sitemap',
                                               help="Enter the urls to be excluded from sitemap")
    }
