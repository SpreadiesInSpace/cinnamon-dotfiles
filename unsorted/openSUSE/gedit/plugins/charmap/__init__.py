# -*- coding: utf-8 -*-
#
# Copyright (C) 2006 Steve Frécinaux <steve@istique.net>
#               2010 Ignacio Casal Quinteiro <icq@gnome.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import sys

import gi
gi.require_version('Gedit', '3.0')
gi.require_version('Pango', '1.0')
gi.require_version('Gtk', '3.0')
gi.require_version('Gucharmap', '2.90')
from gi.repository import GObject, Gio, Pango, Gtk, Tepl, Gedit, Gucharmap
from .panel import CharmapPanel

try:
    import gettext
    gettext.bindtextdomain('gedit-plugins')
    gettext.textdomain('gedit-plugins')
    _ = gettext.gettext
except:
    _ = lambda s: s


class CharmapPlugin(GObject.Object, Gedit.WindowActivatable):
    __gtype_name__ = "CharmapPlugin"

    window = GObject.Property(type=Gedit.Window)

    def __init__(self):
        GObject.Object.__init__(self)

    def do_activate(self):
        self.editor_settings = Gio.Settings.new("org.gnome.gedit.preferences.editor")
        self.editor_settings.connect("changed::use-default-font", self.font_changed)
        self.editor_settings.connect("changed::editor-font", self.font_changed)
        self.system_settings = Gio.Settings.new("org.gnome.desktop.interface")
        self.system_settings.connect("changed::monospace-font-name", self.font_changed)

        self.create_charmap_panel()

        self.side_panel_item = Tepl.PanelItem.new(self.panel,
            "GeditCharmapPanel", _("Character Map"), None, 0)
        side_panel = self.window.get_side_panel()
        Tepl.Panel.add(side_panel, self.side_panel_item)

        statusbar = self.window.get_statusbar()
        self.context_id = statusbar.get_context_id("Character Description")

    def do_deactivate(self):
        side_panel = self.window.get_side_panel()
        Tepl.Panel.remove(side_panel, self.side_panel_item)
        self.side_panel_item = None

    def do_update_state(self):
        self.panel.set_sensitive(len(self.window.get_documents()) >= 1)

    def get_document_font(self):
        if self.editor_settings.get_boolean("use-default-font"):
            font = self.system_settings.get_string("monospace-font-name")
        else:
            font = self.editor_settings.get_string("editor-font")

        return font

    def font_changed(self, settings=None, key=None):
        font = self.get_document_font()
        font_desc = Pango.font_description_from_string(font)

        chartable = self.panel.get_chartable()
        chartable.set_font_desc(font_desc)

    def create_charmap_panel(self):
        self.panel = CharmapPanel()
        chartable = self.panel.get_chartable()

        # Use the same font as the document
        self.font_changed()

        chartable.connect("notify::active-character", self.on_table_sync_active_char)
        chartable.connect("focus-out-event", self.on_table_focus_out_event)
        chartable.connect("status-message", self.on_table_status_message)
        chartable.connect("activate", self.on_table_activate)

        self.panel.show()

    def on_table_sync_active_char(self, chartable, pspec):
        uc = chartable.get_active_character()
        text = "%s %s" % (uc, Gucharmap.get_unicode_name(uc))

        self.on_table_status_message(chartable, text)

    def on_table_focus_out_event(self, chartable, event):
        self.on_table_status_message (chartable, None)

        return False

    def on_table_status_message(self, chartable, message):
        statusbar = self.window.get_statusbar()

        statusbar.pop(self.context_id)

        if message:
            statusbar.push(self.context_id, message)

    def on_table_activate(self, chartable):
        uc = chartable.get_active_character()
        if not Gucharmap.unichar_validate(uc):
            raise ValueError

        view = self.window.get_active_view()
        if not view or not view.get_editable():
            return

        document = view.get_buffer()

        document.begin_user_action()
        iters = document.get_selection_bounds()
        if iters:
            document.delete_interactive(iters[0], iters[1], view.get_editable())

        document.insert_interactive_at_cursor(uc, -1, view.get_editable())

        document.end_user_action()

# ex:et:ts=4:
