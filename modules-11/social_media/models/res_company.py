# -*- coding: utf-8 -*-
##############################################################################
#
# @ddfs. Copyright (c) 2017
#
##############################################################################
from odoo import fields, models


class Company(models.Model):
    _inherit = "res.company"

    social_new_window = fields.Boolean("Open in new window", help="Open all social media links in a new window")
    social_instagram = fields.Char("Instagram Account")
    social_pinterest = fields.Char("Pinterest Account")
