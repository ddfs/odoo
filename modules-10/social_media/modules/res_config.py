# -*- coding: utf-8 -*-

from odoo import fields, models


class WebsiteConfigSettings(models.TransientModel):
    _inherit = 'website.config.settings'

    social_new_window = fields.Boolean(related='website_id.social_new_window')
    social_instagram = fields.Char(related='website_id.social_instagram')
    social_pinterest = fields.Char(related='website_id.social_pinterest')
