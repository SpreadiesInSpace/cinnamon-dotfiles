# -*- coding: utf-8 -*-

# config.py -- Config dialog
#
# Copyright (C) 2008 - B. Clausius
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
# along with this program; if not, see <http://www.gnu.org/licenses/>.

# Parts from "Interactive Python-GTK Console" (stolen from epiphany's console.py)
#     Copyright (C), 1998 James Henstridge <james@daa.com.au>
#     Copyright (C), 2005 Adam Hooper <adamh@densi.com>
# Bits from gedit Python Console Plugin
#     Copyrignt (C), 2005 Raphaël Slinckx

import os
from gi.repository import Gio, Gtk, Gdk

__all__ = ('PythonConsoleConfigWidget')

class PythonConsoleConfigWidget(object):

    CONSOLE_KEY_BASE = 'org.gnome.gedit.plugins.pythonconsole'
    CONSOLE_KEY_COMMAND_COLOR = 'command-color'
    CONSOLE_KEY_ERROR_COLOR = 'error-color'

    def __init__(self, datadir):
        object.__init__(self)

        self._ui_path = os.path.join(datadir, 'ui', 'config.ui')
        self._settings = Gio.Settings.new(self.CONSOLE_KEY_BASE)
        self._ui = Gtk.Builder()

    def configure_widget(self):
        self._ui.add_from_file(self._ui_path)

        self.set_colorbutton_color(self._ui.get_object('colorbutton-command'),
                                   self._settings.get_string(self.CONSOLE_KEY_COMMAND_COLOR))
        self.set_colorbutton_color(self._ui.get_object('colorbutton-error'),
                                   self._settings.get_string(self.CONSOLE_KEY_ERROR_COLOR))

        self._ui.connect_signals(self)

        widget = self._ui.get_object('grid')

        return widget

    @staticmethod
    def set_colorbutton_color(colorbutton, value):
        rgba = Gdk.RGBA()
        parsed = rgba.parse(value)

        if parsed:
            colorbutton.set_rgba(rgba)

    def on_colorbutton_command_color_set(self, colorbutton):
        self._settings.set_string(self.CONSOLE_KEY_COMMAND_COLOR,
                                  colorbutton.get_color().to_string())

    def on_colorbutton_error_color_set(self, colorbutton):
        self._settings.set_string(self.CONSOLE_KEY_ERROR_COLOR,
                                  colorbutton.get_color().to_string())

# ex:et:ts=4:
