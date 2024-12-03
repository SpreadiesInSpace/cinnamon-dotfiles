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

from gi.repository import Gio

class Session(object):
    def __init__(self, name, files = None):
        super(Session, self).__init__()
        self.name = name
        if files is None:
            files = []
        self.files = files

    def __lt__(self, session):
        return (self.name.lower() < session.name.lower())

    def __eq__(self, session):
        return (self.name.lower() == session.name.lower())

    def add_file(self, filename):
        self.files.append(Gio.file_new_for_uri(filename))

# ex:ts=4:et:
