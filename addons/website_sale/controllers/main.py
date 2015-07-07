# -*- coding: utf-8 -*-
import werkzeug

from openerp import SUPERUSER_ID
from openerp import http
from openerp.addons.website_sale.controllers.main import QueryURL, table_compute, website_sale
from openerp.http import request
from openerp.tools.translate import _
from openerp.addons.website.models.website import slug
from openerp.addons.web.controllers.main import login_redirect

PPG = 20 # Products Per Page
PPR = 4  # Products Per Row

class HxnWebsiteSale(website_sale):

    @http.route(['/shop',
        '/shop/page/<int:page>',
        '/shop/category/<model("product.public.category"):category>',
        '/shop/category/<model("product.public.category"):category>/page/<int:page>'
    ], type='http', auth="public", website=True)
    def shop(self, page=0, category=None, search='', **post):
        cr, uid, context, pool = request.cr, request.uid, request.context, request.registry

        domain = request.website.sale_product_domain()
        if search:
            for srch in search.split(" "):
                domain += ['|', '|', '|', ('name', 'ilike', srch), ('description', 'ilike', srch),
                    ('description_sale', 'ilike', srch), ('product_variant_ids.default_code', 'ilike', srch)]
        if category:
            domain += [('public_categ_ids', 'child_of', int(category))]
        attrib_list = request.httprequest.args.getlist('attrib')
        attrib_values = [map(int,v.split("-")) for v in attrib_list if v]
        attrib_set = set([v[1] for v in attrib_values])

        if attrib_values:
            attrib = None
            ids = []
            for value in attrib_values:
                if not attrib:
                    attrib = value[0]
                    ids.append(value[1])
                elif value[0] == attrib:
                    ids.append(value[1])
                else:
                    domain += [('attribute_line_ids.value_ids', 'in', ids)]
                    attrib = value[0]
                    ids = [value[1]]
            if attrib:
                domain += [('attribute_line_ids.value_ids', 'in', ids)]

        keep = QueryURL('/shop', category=category and int(category), search=search, attrib=attrib_list)

        if not context.get('pricelist'):
            pricelist = self.get_pricelist()
            context['pricelist'] = int(pricelist)
        else:
            pricelist = pool.get('product.pricelist').browse(cr, uid, context['pricelist'], context)

        product_obj = pool.get('product.template')

        url = "/shop"
        product_count = product_obj.search_count(cr, uid, domain, context=context)
        if search:
            post["search"] = search
        if category:
            category = pool['product.public.category'].browse(cr, uid, int(category), context=context)
            url = "/shop/category/%s" % slug(category)
        if attrib_list:
            post['attrib'] = attrib_list
        pager = request.website.pager(url=url, total=product_count, page=page, step=PPG, scope=7, url_args=post)
        product_ids = product_obj.search(cr, uid, domain, limit=PPG, offset=pager['offset'], order='website_published desc, website_sequence desc', context=context)
        products = product_obj.browse(cr, uid, product_ids, context=context)

        style_obj = pool['product.style']
        style_ids = style_obj.search(cr, uid, [], context=context)
        styles = style_obj.browse(cr, uid, style_ids, context=context)

        category_obj = pool['product.public.category']
        category_ids = category_obj.search(cr, uid, [('parent_id', '=', False)], context=context)
        categs = category_obj.browse(cr, uid, category_ids, context=context)

        attributes_obj = request.registry['product.attribute']
        attributes_ids = attributes_obj.search(cr, uid, [], context=context)
        attributes = attributes_obj.browse(cr, uid, attributes_ids, context=context)

        from_currency = pool.get('product.price.type')._get_field_currency(cr, uid, 'list_price', context)
        to_currency = pricelist.currency_id
        compute_currency = lambda price: pool['res.currency']._compute(cr, uid, from_currency, to_currency, price, context=context)

        attributes_filtered = []

        if category:
            # collect child category ids
            active_categories = pool['product.public.category'].search(cr, uid, [('parent_id', '=', int(category.id))], context=context)

            # append current category into list
            active_categories.append(category.id)

            sql = """
                SELECT
                    pavppr.att_id
                FROM
                    product_product AS pp
                    LEFT JOIN product_template AS pt ON pp.product_tmpl_id = pt.id
                    LEFT JOIN product_attribute_value_product_product_rel AS pavppr ON pp.id = pavppr.prod_id
                    LEFT JOIN product_attribute_line AS pal ON pp.product_tmpl_id = pal.product_tmpl_id AND pal.attribute_id = pavppr.att_id
                    LEFT JOIN product_attribute AS pa ON pal.attribute_id = pa.id
                    LEFT JOIN product_public_category_product_template_rel AS ppcptr ON pt.id = ppcptr.product_template_id
                    LEFT JOIN product_public_category AS ppc ON ppc.id = ppcptr.product_public_category_id
                WHERE
                    pp.active = TRUE AND
                    pt.sale_ok = TRUE AND
                    pt.website_published = TRUE AND
                    ppc.id IN  (%s)
                GROUP BY
                    pavppr.att_id
                ORDER BY
                    pavppr.att_id ASC
            """
            cr.execute(sql % ','.join("%s" % ac for ac in active_categories))

            attribute_line_results = cr.fetchall()

            for alr in attribute_line_results:
                attributes_filtered.append(alr[0])

        if not category:
            for a in attributes:
                for b in a.value_ids:
                    attributes_filtered.append(b.id)

        values = {
            'search': search,
            'category': category,
            'attrib_values': attrib_values,
            'attrib_set': attrib_set,
            'pager': pager,
            'pricelist': pricelist,
            'products': products,
            'bins': table_compute().process(products),
            'rows': PPR,
            'styles': styles,
            'categories': categs,
            'attributes': attributes,
            'attributes_filtered': attributes_filtered,
            'compute_currency': compute_currency,
            'keep': keep,
            'style_in_product': lambda style, product: style.id in [s.id for s in product.website_style_ids],
            'attrib_encode': lambda attribs: werkzeug.url_encode([('attrib',i) for i in attribs]),
        }
        return request.website.render("website_sale.products", values)
