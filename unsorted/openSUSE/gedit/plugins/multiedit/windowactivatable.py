# -*- coding: utf-8 -*-
#
#  windowactivatable.py - Multi Edit
#
#  Copyright (C) 2014 - Jesse van den Kieboom
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

from gi.repository import GLib, GObject, Gio, Gedit

from .viewactivatable import MultiEditViewActivatable


class MultiEditWindowActivatable(GObject.Object, Gedit.WindowActivatable):

    window = GObject.Property(type=Gedit.Window)

    def do_activate(self):
        action = Gio.SimpleAction.new_stateful("multiedit", None, GLib.Variant.new_boolean(False))
        action.connect('activate', self.activate_toggle)
        action.connect('change-state', self.multi_edit_mode)
        self.window.add_action(action)

        self.window.multiedit_window_activatable = self

    def do_deactivate(self):
        self.window.remove_action("multiedit")
        delattr(self.window, 'multiedit_window_activatable')

    def do_update_state(self):
        view = self.get_view_activatable(self.window.get_active_view())
        self.get_action().set_state(GLib.Variant.new_boolean(view != None and view.enabled()))

    def get_view_activatable(self, view):
        if not hasattr(view, "multiedit_view_activatable"):
            return None
        return view.multiedit_view_activatable

    def get_action(self):
        return self.window.lookup_action("multiedit")

    def on_multi_edit_toggled(self, viewactivatable):
        if viewactivatable.view == self.window.get_active_view():
            self.get_action().set_state(GLib.Variant.new_boolean(viewactivatable.enabled()))

    def activate_toggle(self, action, parameter):
        state = action.get_state()
        action.change_state(GLib.Variant.new_boolean(not state.get_boolean()))

    def multi_edit_mode(self, action, state):
        view = self.window.get_active_view()
        helper = self.get_view_activatable(view)

        active = state.get_boolean()

        if helper != None:
            helper.toggle_multi_edit(active)

        action.set_state(GLib.Variant.new_boolean(active))

# ex:ts=4:et:
