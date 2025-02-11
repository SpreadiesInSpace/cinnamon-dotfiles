# -*- coding: utf-8 -*-
#
#  multiedit.py - Multi Edit
#
#  Copyright (C) 2009 - Jesse van den Kieboom
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

try:
    import gettext
    gettext.bindtextdomain('gedit-plugins')
    gettext.textdomain('gedit-plugins')
    _ = gettext.gettext
except:
    _ = lambda s: s


class MultiEditAppActivatable(GObject.Object, Gedit.AppActivatable):

    app = GObject.Property(type=Gedit.App)

    def __init__(self):
        GObject.Object.__init__(self)

    def do_activate(self):
        self.app.add_accelerator("<Primary><Shift>C", "win.multiedit", None)

        self.menu_ext = self.extend_menu("tools-section")
        item = Gio.MenuItem.new(_('Multi Edit Mode'), "win.multiedit")
        self.menu_ext.append_menu_item(item)

    def do_deactivate(self):
        self.app.remove_accelerator("win.multiedit", None)
        self.menu_ext = None

# ex:ts=4:et:
