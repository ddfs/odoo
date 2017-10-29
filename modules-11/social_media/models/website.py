# -*- coding: utf-8 -*-
##############################################################################
#
# @ddfs.  Copyright (c) 2017
#
##############################################################################

from odoo import fields, models


class Website(models.Model):
    _inherit = 'website'

    social_new_window = fields.Boolean(related='company_id.social_new_window')
    social_instagram = fields.Char(related='company_id.social_instagram')
    social_pinterest = fields.Char(related='company_id.social_pinterest')
