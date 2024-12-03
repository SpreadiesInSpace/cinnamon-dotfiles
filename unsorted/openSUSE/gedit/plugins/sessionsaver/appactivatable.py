# -*- coding: utf-8 -*-
#
#  Copyrignt (C) 2019 Jordi Mas <jmas@softcatala.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor,
#  Boston, MA 02110-1301, USA.

from gi.repository import GObject, Gio, Gedit
from .store.xmlsessionstore import XMLSessionStore

try:
    import gettext
    gettext.bindtextdomain('gedit-plugins')
    gettext.textdomain('gedit-plugins')
    _ = gettext.gettext
except:
    _ = lambda s: s



class SessionSaverAppActivatable(GObject.Object, Gedit.AppActivatable):

    app = GObject.Property(type=Gedit.App)
    __instance = None

    def __init__(self):
        GObject.Object.__init__(self)
        SessionSaverAppActivatable.__instance = self

    @classmethod
    def get_instance(cls):
        return cls.__instance

    def do_activate(self):
        self._insert_session_menu()

    def do_deactivate(self):
        self.menu_ext = None

    def _insert_session_menu(self):
        self.menu_ext = self.extend_menu("tools-section")

        item = Gio.MenuItem.new(_("_Manage Saved Sessions…"), "win.managedsession")
        self.menu_ext.append_menu_item(item)

        item = Gio.MenuItem.new(_("_Save Session…"), "win.savesession")
        self.menu_ext.append_menu_item(item)

        self.sessions = XMLSessionStore()
        for i, session in enumerate(self.sessions):
            session_id = 'win.session_{0}'.format(i)
            item = Gio.MenuItem.new(_("Recover “{0}” Session").format(session.name), session_id)
            self.menu_ext.append_menu_item(item)

    def _remove_session_menu(self):
        self.menu_ext.remove_items()

    def update_session_menu(self):
        self._remove_session_menu()
        self._insert_session_menu()
