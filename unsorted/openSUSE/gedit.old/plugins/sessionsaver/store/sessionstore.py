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
from gi.repository import GObject, GLib, Gio
from .session import Session

class SessionStore(GObject.Object):
    __gsignals__ = {
        "session-added":    (GObject.SIGNAL_RUN_LAST, GObject.TYPE_NONE,
                             (GObject.TYPE_PYOBJECT,)),
        "session-changed":  (GObject.SIGNAL_RUN_LAST, GObject.TYPE_NONE,
                             (GObject.TYPE_PYOBJECT,)),
        "session-removed":  (GObject.SIGNAL_RUN_LAST, GObject.TYPE_NONE,
                            (GObject.TYPE_PYOBJECT,))
    }

    def __init__(self):
        super(SessionStore, self).__init__()
        self._sessions = []

    def __iter__(self):
        return iter(self._sessions)

    def __getitem__(self, index):
        return self._sessions[index]

    def __getslice__(self, i, j):
        return self._sessions[i:j]

    def __len__(self):
        return len(self._sessions)

    def do_session_added(self, session):
        self._sessions.append(session)
        self._sessions.sort()

    def do_session_changed(self, session):
        index = self._sessions.index(session)
        self._sessions[index] = session

    def add(self, session):
        assert isinstance(session, Session)

        if session in self:
            self.emit('session-changed', session)
        else:
            self.emit('session-added', session)

    def do_session_removed(self, session):
        self._sessions.remove(session)

    def remove(self, session):
        assert isinstance(session, Session)
        if session in self:
            self.emit('session-removed', session)

    def index(self, session):
        return self._sessions.index(session)

# ex:ts=4:et:
