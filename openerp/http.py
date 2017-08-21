# -*- coding: utf-8 -*-
import datetime
import hashlib
import mimetypes
import os
import time
from zlib import adler32

import werkzeug.contrib.sessions
import werkzeug.datastructures
import werkzeug.exceptions
import werkzeug.local
import werkzeug.routing
import werkzeug.wrappers
import werkzeug.wsgi
from werkzeug.wsgi import wrap_file

import openerp
from openerp import http
from openerp.http import Response

request = http._request_stack()
md5 = hashlib.md5()


def send_file(filepath_or_fp, mimetype=None, as_attachment=False, filename=None, mtime=None,
              add_etags=True, cache_timeout=http.STATIC_CACHE, conditional=True):
    """This is a modified version of Flask's send_file()

    Sends the contents of a file to the client. This will use the
    most efficient method available and configured.  By default it will
    try to use the WSGI server's file_wrapper support.

    By default it will try to guess the mimetype for you, but you can
    also explicitly provide one.  For extra security you probably want
    to send certain files as attachment (HTML for instance).  The mimetype
    guessing requires a `filename` or an `attachment_filename` to be
    provided.

    Please never pass filenames to this function from user sources without
    checking them first.

    :param filepath_or_fp: the filename of the file to send.
                           Alternatively a file object might be provided
                           in which case `X-Sendfile` might not work and
                           fall back to the traditional method.  Make sure
                           that the file pointer is positioned at the start
                           of data to send before calling :func:`send_file`.
    :param mimetype: the mimetype of the file if provided, otherwise
                     auto detection happens.
    :param as_attachment: set to `True` if you want to send this file with
                          a ``Content-Disposition: attachment`` header.
    :param filename: the filename for the attachment if it differs from the file's filename or
                     if using file object without 'name' attribute (eg: E-tags with StringIO).
    :param mtime: last modification time to use for contitional response.
    :param add_etags: set to `False` to disable attaching of etags.
    :param conditional: set to `False` to disable conditional responses.

    :param cache_timeout: the timeout in seconds for the headers.
    """
    if isinstance(filepath_or_fp, (str, unicode)):
        if not filename:
            filename = os.path.basename(filepath_or_fp)
        file = open(filepath_or_fp, 'rb')
        if not mtime:
            mtime = os.path.getmtime(filepath_or_fp)
    else:
        file = filepath_or_fp
        if not filename:
            filename = getattr(file, 'name', None)

    file.seek(0, 2)
    size = file.tell()
    file.seek(0)

    if mimetype is None and filename:
        mimetype = mimetypes.guess_type(filename)[0]
    if mimetype is None:
        mimetype = 'application/octet-stream'

    headers = werkzeug.datastructures.Headers()
    if as_attachment:
        if filename is None:
            raise TypeError('filename unavailable, required for sending as attachment')
        headers.add('Content-Disposition', 'attachment', filename=filename)
        headers['Content-Length'] = size

    data = wrap_file(request.httprequest.environ, file)
    rv = Response(data, mimetype=mimetype, headers=headers,
                  direct_passthrough=True)

    if isinstance(mtime, str):
        try:
            server_format = openerp.tools.misc.DEFAULT_SERVER_DATETIME_FORMAT
            mtime = datetime.datetime.strptime(mtime.split('.')[0], server_format)
        except Exception:
            mtime = None
    if mtime is not None:
        rv.last_modified = mtime

    rv.cache_control.public = True
    if cache_timeout:
        rv.cache_control.max_age = cache_timeout
        rv.expires = int(time.time() + cache_timeout)

    if add_etags and filename and mtime:
        etag_str = 'odoo-%s-%s-%s' % (
            mtime,
            size,
            adler32(
                filename.encode('utf-8') if isinstance(filename, unicode)
                else filename
            ) & 0xffffffff
        )

        # hide odoo string from etags
        rv.set_etag(hashlib.md5(etag_str).hexdigest())

        if conditional:
            rv = rv.make_conditional(request.httprequest)
            # make sure we don't send x-sendfile for servers that
            # ignore the 304 status code for x-sendfile.
            if rv.status_code == 304:
                rv.headers.pop('x-sendfile', None)
    return rv


http.send_file = send_file
