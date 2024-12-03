# -*- coding: utf-8 -*-
#  Color picker plugin
#  This file is part of gedit-plugins
#
#  Copyright (C) 2006 Jesse van den Kieboom
#  Copyright (C) 2012 Ignacio Casal Quinteiro
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

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gedit', '3.0')
from gi.repository import GObject, Gio, Gtk, Gdk, Gedit
import re

try:
    import gettext
    gettext.bindtextdomain('gedit-plugins')
    gettext.textdomain('gedit-plugins')
    _ = gettext.gettext
except:
    _ = lambda s: s


class ColorHelper:

    def scale_color_component(self, component):
        return min(max(int(round(component * 255.)), 0), 255)

    def skip_hex(self, buf, iter, next_char):
        while True:
            char = iter.get_char()

            if not char:
                return

            if char.lower() not in \
                    ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                     'a', 'b', 'c', 'd', 'e', 'f'):
                return

            if not next_char(iter):
                return

    def get_rgba_position(self, buf, use_bounds):
        bounds = buf.get_selection_bounds()
        if bounds == ():
            if use_bounds:
                return None

            # No selection, find color in the current cursor position
            start = buf.get_iter_at_mark(buf.get_insert())

            end = start.copy()
            start.backward_char()

            self.skip_hex(buf, start, lambda iter: iter.backward_char())
            self.skip_hex(buf, end, lambda iter: iter.forward_char())
        else:
            start, end = bounds

        text = buf.get_text(start, end, False)

        if not re.match('#?[0-9a-zA-Z]+', text):
            return None

        if text[0] != '#':
            start.backward_char()

            if start.get_char() != '#':
                return None

        return start, end

    def insert_color(self, view, text):
        if not view or not view.get_editable():
            return

        doc = view.get_buffer()

        if not doc:
            return

        doc.begin_user_action()

        # Get the color
        bounds = self.get_rgba_position(doc, False)

        if not bounds:
            doc.delete_selection(False, True)
        else:
            doc.delete(bounds[0], bounds[1])

        doc.insert_at_cursor('#' + text)

        doc.end_user_action()

    def get_current_color(self, doc, use_bounds):
        if not doc:
            return None

        bounds = self.get_rgba_position(doc, use_bounds)

        if bounds:
            return doc.get_text(bounds[0], bounds[1], False)
        else:
            return None


class ColorPickerAppActivatable(GObject.Object, Gedit.AppActivatable):

    app = GObject.Property(type=Gedit.App)

    def __init__(self):
        GObject.Object.__init__(self)

    def do_activate(self):
        self.menu_ext = self.extend_menu("tools-section")
        item = Gio.MenuItem.new(_("Pick _Color…"), "win.colorpicker")
        self.menu_ext.prepend_menu_item(item)

    def do_deactivate(self):
        self.menu_ext = None


class ColorPickerWindowActivatable(GObject.Object, Gedit.WindowActivatable):

    window = GObject.Property(type=Gedit.Window)

    def __init__(self):
        GObject.Object.__init__(self)
        self._dialog = None
        self._color_helper = ColorHelper()

    def do_activate(self):
        action = Gio.SimpleAction(name="colorpicker")
        action.connect('activate', lambda a, p: self.on_color_picker_activate())
        self.window.add_action(action)
        self._update()

    def do_deactivate(self):
        self.window.remove_action("colorpicker")

    def do_update_state(self):
        self._update()

    def _update(self):
        tab = self.window.get_active_tab()
        self.window.lookup_action("colorpicker").set_enabled(tab is not None)

        if not tab and self._dialog and \
                self._dialog.get_transient_for() == self.window:
            self._dialog.response(Gtk.ResponseType.CLOSE)

    # Signal handlers

    def on_color_picker_activate(self):
        if not self._dialog:
            self._dialog = Gtk.ColorChooserDialog.new(_('Pick Color'), self.window)
            self._dialog.connect_after('response', self.on_dialog_response)

        rgba_str = self._color_helper.get_current_color(self.window.get_active_document(), False)

        if rgba_str:
            rgba = Gdk.RGBA()
            parsed = rgba.parse(rgba_str)

            if parsed:
                self._dialog.set_rgba(rgba)

        self._dialog.present()

    def on_dialog_response(self, dialog, response):
        if response == Gtk.ResponseType.OK:
            rgba = dialog.get_rgba()

            self._color_helper.insert_color(self.window.get_active_view(),
                                            "%02x%02x%02x" % (self._color_helper.scale_color_component(rgba.red),
                                                              self._color_helper.scale_color_component(rgba.green),
                                                              self._color_helper.scale_color_component(rgba.blue)))
        else:
            self._dialog.destroy()
            self._dialog = None


class ColorPickerViewActivatable(GObject.Object, Gedit.ViewActivatable):

    view = GObject.Property(type=Gedit.View)

    def __init__(self):
        GObject.Object.__init__(self)
        self._rgba_str = None
        self._color_button = None
        self._color_helper = ColorHelper()

    def do_activate(self):

        buf = self.view.get_buffer()
        buf.connect_after('mark-set', self.on_buffer_mark_set)

    def do_deactivate(self):
        if self._color_button is not None:
            self._color_button.destroy()
            self._color_button = None

    def on_buffer_mark_set(self, buf, location, mark):

        if not buf.get_has_selection():
            if self._color_button:
                self._color_button.destroy()
                self._color_button = None
            return

        if mark != buf.get_insert() and mark != buf.get_selection_bound():
            return

        rgba_str = self._color_helper.get_current_color(self.view.get_buffer(), True)
        if rgba_str is not None and rgba_str != self._rgba_str and self._color_button is not None:
            rgba = Gdk.RGBA()
            parsed = rgba.parse(rgba_str)
            if parsed:
                self._rgba_str = rgba_str
                self._color_button.set_rgba(rgba)
        elif rgba_str is not None and self._color_button is None:
            rgba = Gdk.RGBA()
            parsed = rgba.parse(rgba_str)
            if parsed:
                self._rgba_str = rgba_str

                bounds = buf.get_selection_bounds()
                if bounds != ():
                    self._color_button = Gtk.ColorButton.new_with_rgba(rgba)
                    self._color_button.set_halign(Gtk.Align.START)
                    self._color_button.set_valign(Gtk.Align.START)
                    self._color_button.show()
                    self._color_button.connect('color-set', self.on_color_set)

                    start, end = bounds
                    location = self.view.get_iter_location(start)
                    min_width, nat_width = self._color_button.get_preferred_width()
                    min_height, nat_height = self._color_button.get_preferred_height()
                    x = location.x
                    if location.y - nat_height > 0:
                        y = location.y - nat_height
                    else:
                        y = location.y + location.height

                    self.view.add_child_in_window(self._color_button, Gtk.TextWindowType.TEXT, x, y)
        elif not rgba_str and self._color_button is not None:
            self._color_button.destroy()
            self._color_button = None

    def on_color_set(self, color_button):
        rgba = color_button.get_rgba()

        self._color_helper.insert_color(self.view,
                                        "%02x%02x%02x" % (self._color_helper.scale_color_component(rgba.red),
                                                          self._color_helper.scale_color_component(rgba.green),
                                                          self._color_helper.scale_color_component(rgba.blue)))

# ex:ts=4:et:
