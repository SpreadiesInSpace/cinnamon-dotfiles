# -*- coding: utf-8 -*-
# store.py
# This file is part of gedit Session Saver Plugin
#
# Copyright (C) 2006-2007 - Steve Frécinaux <code@istique.net>
# Copyright (C) 2010 - Kenny Meyer <knny.myer@gmail.com>
#
# gedit Session Saver Plugin is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# gedit Session Saver Plugin is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with gedit Session Saver Plugin; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor,
# Boston, MA  02110-1301  USA

import os.path
from xml.parsers import expat
from gi.repository import GLib
from .sessionstore import SessionStore
from .session import Session

class XMLSessionStore(SessionStore):
    def __init__(self, filename = None):
        super(XMLSessionStore, self).__init__()

        if filename is None:
            self.filename = os.path.join(GLib.get_user_config_dir(), 'gedit/saved-sessions.xml')
        else:
            self.filename = filename

        self.load()

    def _escape(self, string):
        return string.replace('&', '&amp;') \
                     .replace('<', '&lt;')  \
                     .replace('>', '&gt;')  \
                     .replace('"', '&quot;')

    def _dump_session(self, session):
        files = ''.join(['  <file path="%s"/>\n' % self._escape(location.get_uri())
                            for location in session.files])
        session_name = self._escape(str(session.name))
        return '<session name="%s">\n%s</session>\n' % (session_name, files)

    def dump(self):
        dump = [self._dump_session(session) for session in self]
        return '<saved-sessions>\n%s</saved-sessions>\n' % ''.join(dump)

    def save(self):
        dirname = os.path.dirname(self.filename)
        if not os.path.isdir(dirname):
            os.makedirs(dirname)

        fp = open(self.filename, "wb")
        fp.write(bytes('<?xml version="1.0" encoding="UTF-8"?>\n','UTF-8'))
        fp.write(bytes(self.dump(),'UTF-8'))
        fp.close()

    def load(self):
        if not os.path.isfile(self.filename):
            return

        parser = expat.ParserCreate('UTF-8')
        parser.buffer_text = True
        parser.StartElementHandler = self._expat_start_handler
        parser.EndElementHandler = self._expat_end_handler

        self._current_session = None
        try:
            parser.ParseFile(open(self.filename, 'rb'))
        except:
            return
        del self._current_session

    def _expat_start_handler(self, tag, attr):
        if tag == 'file':
            assert self._current_session is not None
            self._current_session.add_file(str(attr['path']))
        elif tag == 'session':
            assert self._current_session is None
            self._current_session = Session(attr['name'])

    def _expat_end_handler(self, tag):
        if tag == 'session':
            self.add(self._current_session)
            self._current_session = None

# ex:ts=4:et:
