# -*- coding: utf8 -*-

# terminal.py - Embeded VTE terminal for gedit
# This file is part of gedit
#
# Copyright (C) 2005-2006 - Paolo Borelli
#
# gedit is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# gedit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with gedit; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor,
# Boston, MA  02110-1301  USA

import os

import gi
gi.require_version('Gedit', '3.0')
gi.require_version('Gtk', '3.0')
gi.require_version('Vte', '2.91')
gi.require_version('Tepl', '6')
from gi.repository import GObject, GLib, Gio, Pango, Gdk, Gtk, Gedit, Tepl, Vte

try:
    import gettext
    gettext.bindtextdomain('gedit-plugins')
    gettext.textdomain('gedit-plugins')
    _ = gettext.gettext
except:
    _ = lambda s: s

class GeditTerminal(Vte.Terminal):

    defaults = {
        'audible_bell'          : False,
    }

    SETTINGS_SCHEMA_ID_BASE = "org.gnome.Terminal.ProfilesList"
    SETTINGS_SCHEMA_ID_FALLBACK = "org.gnome.gedit.plugins.terminal"
    SETTING_KEY_PROFILE_USE_SYSTEM_FONT = "use-system-font"
    SETTING_KEY_PROFILE_FONT = "font"
    SETTING_KEY_PROFILE_USE_THEME_COLORS = "use-theme-colors"
    SETTING_KEY_PROFILE_FOREGROUND_COLOR = "foreground-color"
    SETTING_KEY_PROFILE_BACKGROUND_COLOR = "background-color"
    SETTING_KEY_PROFILE_PALETTE = "palette"
    SETTING_KEY_PROFILE_CURSOR_BLINK_MODE = "cursor-blink-mode"
    SETTING_KEY_PROFILE_CURSOR_SHAPE = "cursor-shape"
    SETTING_KEY_PROFILE_AUDIBLE_BELL = "audible-bell"
    SETTING_KEY_PROFILE_SCROLL_ON_KEYSTROKE = "scroll-on-keystroke"
    SETTING_KEY_PROFILE_SCROLL_ON_OUTPUT = "scroll-on-output"
    SETTING_KEY_PROFILE_SCROLLBACK_UNLIMITED = "scrollback-unlimited"
    SETTING_KEY_PROFILE_SCROLLBACK_LINES = "scrollback-lines"

    TARGET_URI_LIST = 200

    def __init__(self):
        Vte.Terminal.__init__(self)

        self.set_size(self.get_column_count(), 5)
        self.set_size_request(200, 50)

        tl = Gtk.TargetList.new([])
        tl.add_uri_targets(self.TARGET_URI_LIST)

        self.drag_dest_set(Gtk.DestDefaults.HIGHLIGHT | Gtk.DestDefaults.DROP,
                           [], Gdk.DragAction.DEFAULT | Gdk.DragAction.COPY)
        self.drag_dest_set_target_list(tl)

        self.profile_settings = self.get_profile_settings()
        self.profile_settings.connect("changed", self.on_profile_settings_changed)
        self.system_settings = Gio.Settings.new("org.gnome.desktop.interface")
        self.system_settings.connect("changed::monospace-font-name", self.font_changed)

        self.reconfigure_vte()

        self.spawn_sync(Vte.PtyFlags.DEFAULT, None, [Vte.get_user_shell()], None, GLib.SpawnFlags.SEARCH_PATH, None, None, None)

    def do_drag_data_received(self, drag_context, x, y, data, info, time):
        if info == self.TARGET_URI_LIST:
            self.feed_child(' '.join(["'" + Gio.file_new_for_uri(item).get_path() + "'" for item in Gedit.utils_drop_get_uris(data)]).encode('utf-8'))
            Gtk.drag_finish(drag_context, True, False, time);
        else:
            Vte.Terminal.do_drag_data_received(self, drag_context, x, y, data, info, time)

    def get_profile_settings(self):
        fallback_settings = Gio.Settings.new(self.SETTINGS_SCHEMA_ID_FALLBACK)

        if not Tepl.utils_can_use_gsettings_schema(self.SETTINGS_SCHEMA_ID_BASE):
            return fallback_settings

        profiles = Gio.Settings.new(self.SETTINGS_SCHEMA_ID_BASE)
        if not Tepl.utils_can_use_gsettings_key(profiles, "default"):
            return fallback_settings

        default_path = "/org/gnome/terminal/legacy/profiles:/:" + profiles.get_string("default") + "/"

        if not Tepl.utils_can_use_gsettings_schema("org.gnome.Terminal.Legacy.Profile"):
            return fallback_settings

        settings = Gio.Settings.new_with_path("org.gnome.Terminal.Legacy.Profile", default_path)

        if (Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_USE_SYSTEM_FONT) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_FONT) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_USE_THEME_COLORS) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_FOREGROUND_COLOR) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_BACKGROUND_COLOR) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_PALETTE) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_CURSOR_BLINK_MODE) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_CURSOR_SHAPE) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_AUDIBLE_BELL) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_SCROLL_ON_KEYSTROKE) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_SCROLL_ON_OUTPUT) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_SCROLLBACK_UNLIMITED) and
            Tepl.utils_can_use_gsettings_key(settings, self.SETTING_KEY_PROFILE_SCROLLBACK_LINES)):
            return settings

        return fallback_settings

    def get_font(self):
        if self.profile_settings.get_boolean(self.SETTING_KEY_PROFILE_USE_SYSTEM_FONT):
            font = self.system_settings.get_string("monospace-font-name")
        else:
            font = self.profile_settings.get_string(self.SETTING_KEY_PROFILE_FONT)

        return font

    def font_changed(self, settings=None, key=None):
        font = self.get_font()
        font_desc = Pango.font_description_from_string(font)

        self.set_font(font_desc)

    def reconfigure_vte(self):
        # Fonts
        self.font_changed()

        # colors
        context = self.get_style_context()
        fg = context.get_color(Gtk.StateFlags.NORMAL)
        bg = context.get_background_color(Gtk.StateFlags.NORMAL)
        palette = []

        if not self.profile_settings.get_boolean(self.SETTING_KEY_PROFILE_USE_THEME_COLORS):
            fg_color = self.profile_settings.get_string(self.SETTING_KEY_PROFILE_FOREGROUND_COLOR)
            if fg_color != "":
                fg = Gdk.RGBA()
                parsed = fg.parse(fg_color)
            bg_color = self.profile_settings.get_string(self.SETTING_KEY_PROFILE_BACKGROUND_COLOR)
            if bg_color != "":
                bg = Gdk.RGBA()
                parsed = bg.parse(bg_color)
        str_colors = self.profile_settings.get_strv(self.SETTING_KEY_PROFILE_PALETTE)
        if str_colors:
            for str_color in str_colors:
                try:
                    rgba = Gdk.RGBA()
                    rgba.parse(str_color)
                    palette.append(rgba)
                except:
                    palette = []
                    break

        self.set_colors(fg, bg, palette)
        self.set_cursor_blink_mode(self.profile_settings.get_enum(self.SETTING_KEY_PROFILE_CURSOR_BLINK_MODE))
        self.set_cursor_shape(self.profile_settings.get_enum(self.SETTING_KEY_PROFILE_CURSOR_SHAPE))
        self.set_audible_bell(self.profile_settings.get_boolean(self.SETTING_KEY_PROFILE_AUDIBLE_BELL))
        self.set_scroll_on_keystroke(self.profile_settings.get_boolean(self.SETTING_KEY_PROFILE_SCROLL_ON_KEYSTROKE))
        self.set_scroll_on_output(self.profile_settings.get_boolean(self.SETTING_KEY_PROFILE_SCROLL_ON_OUTPUT))
        self.set_audible_bell(self.defaults['audible_bell'])

        if self.profile_settings.get_boolean(self.SETTING_KEY_PROFILE_SCROLLBACK_UNLIMITED):
            lines = -1
        else:
            lines = self.profile_settings.get_int(self.SETTING_KEY_PROFILE_SCROLLBACK_LINES)
        self.set_scrollback_lines(lines)

    def on_profile_settings_changed(self, settings, key):
        self.reconfigure_vte()

class GeditTerminalPanel(Gtk.Box):
    """VTE terminal which follows gnome-terminal default profile options"""

    __gsignals__ = {
        "populate-popup": (
            GObject.SignalFlags.RUN_LAST,
            None,
            (GObject.TYPE_OBJECT,)
        )
    }

    def __init__(self):
        Gtk.Box.__init__(self)

        self._accel_base = '<gedit>/plugins/terminal'
        self._accels = {
            'copy-clipboard': [Gdk.KEY_C, Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK, self.copy_clipboard],
            'paste-clipboard': [Gdk.KEY_V, Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK, self.paste_clipboard]
        }

        for name in self._accels:
            path = self._accel_base + '/' + name
            accel = Gtk.AccelMap.lookup_entry(path)

            if not accel[0]:
                 Gtk.AccelMap.add_entry(path, self._accels[name][0], self._accels[name][1])

        self.add_terminal()

    def add_terminal(self):
        self._vte = GeditTerminal()
        self._vte.show()
        self.pack_start(self._vte, True, True, 0)

        self._vte.connect("child-exited", self.on_vte_child_exited)
        self._vte.connect("key-press-event", self.on_vte_key_press)
        self._vte.connect("button-press-event", self.on_vte_button_press)
        self._vte.connect("popup-menu", self.on_vte_popup_menu)

        scrollbar = Gtk.Scrollbar.new(Gtk.Orientation.VERTICAL, self._vte.get_vadjustment())
        scrollbar.show()
        self.pack_start(scrollbar, False, False, 0)

    def on_vte_child_exited(self, term, status):
        for child in self.get_children():
            child.destroy()

        self.add_terminal()
        self._vte.grab_focus()

    def do_grab_focus(self):
        self._vte.grab_focus()

    def on_vte_key_press(self, term, event):
        modifiers = event.state & Gtk.accelerator_get_default_mod_mask()
        if event.keyval in (Gdk.KEY_Tab, Gdk.KEY_KP_Tab, Gdk.KEY_ISO_Left_Tab):
            if modifiers == Gdk.ModifierType.CONTROL_MASK:
                self.get_toplevel().child_focus(Gtk.DirectionType.TAB_FORWARD)
                return True
            elif modifiers == Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK:
                self.get_toplevel().child_focus(Gtk.DirectionType.TAB_BACKWARD)
                return True

        for name in self._accels:
            path = self._accel_base + '/' + name
            entry = Gtk.AccelMap.lookup_entry(path)

            if entry and entry[0] and entry[1].accel_key == event.keyval and entry[1].accel_mods == modifiers:
                self._accels[name][2]()
                return True

        keyval_name = Gdk.keyval_name(Gdk.keyval_to_upper(event.keyval))

        # Special case some Vte.Terminal shortcuts
        # so the global shortcuts do not override them
        if modifiers == Gdk.ModifierType.CONTROL_MASK and keyval_name in 'ACDEHKLRTUWZ':
            return False

        if modifiers == Gdk.ModifierType.MOD1_MASK and keyval_name in 'BF':
            return False

        return Gtk.accel_groups_activate(self.get_toplevel(),
                                         event.keyval, modifiers)

    def on_vte_button_press(self, term, event):
        if event.button == 3:
            self._vte.grab_focus()
            self.make_popup(event)
            return True

        return False

    def on_vte_popup_menu(self, term):
        self.make_popup()

    def create_popup_menu(self):
        menu = Gtk.Menu()

        item = Gtk.ImageMenuItem.new_from_stock(Gtk.STOCK_COPY, None)
        item.connect("activate", lambda menu_item: self.copy_clipboard())
        item.set_accel_path(self._accel_base + '/copy-clipboard')
        item.set_sensitive(self._vte.get_has_selection())
        menu.append(item)

        item = Gtk.ImageMenuItem.new_from_stock(Gtk.STOCK_PASTE, None)
        item.connect("activate", lambda menu_item: self.paste_clipboard())
        item.set_accel_path(self._accel_base + '/paste-clipboard')
        menu.append(item)

        self.emit("populate-popup", menu)
        menu.show_all()
        return menu

    def make_popup(self, event = None):
        menu = self.create_popup_menu()
        menu.attach_to_widget(self, None)

        if event is not None:
            menu.popup_at_pointer(event)
        else:
            menu.popup_at_widget(self,
                                 Gdk.Gravity.NORTH_WEST,
                                 Gdk.Gravity.SOUTH_WEST,
                                 None)
            menu.select_first(False)

    def copy_clipboard(self):
        self._vte.copy_clipboard()
        self._vte.grab_focus()

    def paste_clipboard(self):
        self._vte.paste_clipboard()
        self._vte.grab_focus()

    def change_directory(self, path):
        path = path.replace('\\', '\\\\').replace('"', '\\"')
        self._vte.feed_child(('cd "%s"\n' % path).encode('utf-8'))
        self._vte.grab_focus()

class TerminalPlugin(GObject.Object, Gedit.WindowActivatable):
    __gtype_name__ = "TerminalPlugin"

    window = GObject.Property(type=Gedit.Window)

    def __init__(self):
        GObject.Object.__init__(self)

    def do_activate(self):
        self._panel = GeditTerminalPanel()
        self._panel.connect("populate-popup", self.on_panel_populate_popup)
        self._panel.show()

        bottom = self.window.get_bottom_panel()
        self.panel_item = Tepl.PanelItem.new(self._panel, "GeditTerminalPanel",
            _("Terminal"), None, 0)
        bottom.add(self.panel_item)

    def do_deactivate(self):
        bottom = self.window.get_bottom_panel()
        bottom.remove(self.panel_item)
        self.panel_item = None

    def do_update_state(self):
        pass

    def get_active_document_directory(self):
        doc = self.window.get_active_document()
        if doc:
            location = doc.get_file().get_location()
            if location and location.has_uri_scheme("file"):
                directory = location.get_parent()
                return directory.get_path()
        return None

    def on_panel_populate_popup(self, panel, menu):
        menu.prepend(Gtk.SeparatorMenuItem())
        path = self.get_active_document_directory()
        item = Gtk.MenuItem.new_with_mnemonic(_("C_hange Directory"))
        item.connect("activate", lambda menu_item: panel.change_directory(path))
        item.set_sensitive(path is not None)
        menu.prepend(item)

# Let's conform to PEP8
# ex:ts=4:et:
