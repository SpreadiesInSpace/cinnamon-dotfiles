# -*- coding: utf-8 -*-
#  Join lines plugin
#  This file is part of gedit
#
#  Copyright (C) 2006-2007 Steve Frécinaux, André Homeyer
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

from gi.repository import GObject, Gio, Gtk, Gedit

try:
    import gettext
    gettext.bindtextdomain('gedit-plugins')
    gettext.textdomain('gedit-plugins')
    _ = gettext.gettext
except:
    _ = lambda s: s


class JoinLinesAppActivatable(GObject.Object, Gedit.AppActivatable):
    app = GObject.Property(type=Gedit.App)

    def __init__(self):
        GObject.Object.__init__(self)

    def do_activate(self):
        self.app.add_accelerator("<Primary>J", "win.joinlines", None)
        self.app.add_accelerator("<Primary><Shift>J", "win.splitlines", None)

    def do_deactivate(self):
        self.app.remove_accelerator("win.joinlines", None)
        self.app.remove_accelerator("win.splitlines", None)


class JoinLinesWindowActivatable(GObject.Object, Gedit.WindowActivatable):

    window = GObject.Property(type=Gedit.Window)

    def __init__(self):
        GObject.Object.__init__(self)

    def do_activate(self):
        action = Gio.SimpleAction(name="joinlines")
        action.connect('activate', lambda a, p: self.join_lines())
        self.window.add_action(action)

        action = Gio.SimpleAction(name="splitlines")
        action.connect('activate', lambda a, p: self.split_lines())
        self.window.add_action(action)

    def do_deactivate(self):
        self.window.remove_action("joinlines")
        self.window.remove_action("splitlines")

    def do_update_state(self):
        view = self.window.get_active_view()
        enable = view is not None and view.get_editable()
        self.window.lookup_action("joinlines").set_enabled(enable)
        self.window.lookup_action("splitlines").set_enabled(enable)

    def join_lines(self):
        view = self.window.get_active_view()
        if view and hasattr(view, "join_lines_view_activatable"):
            view.join_lines_view_activatable.join_lines()

    def split_lines(self):
        view = self.window.get_active_view()
        if view and hasattr(view, "join_lines_view_activatable"):
            view.join_lines_view_activatable.split_lines()


class JoinLinesViewActivatable(GObject.Object, Gedit.ViewActivatable):

    view = GObject.Property(type=Gedit.View)

    def __init__(self):
        self.popup_handler_id = 0
        GObject.Object.__init__(self)

    def do_activate(self):
        self.view.join_lines_view_activatable = self
        self.popup_handler_id = self.view.connect('populate-popup', self.populate_popup)

    def do_deactivate(self):
        if self.popup_handler_id != 0:
            self.view.disconnect(self.popup_handler_id)
            self.popup_handler_id = 0
        delattr(self.view, "join_lines_view_activatable")

    def populate_popup(self, view, popup):
        if not isinstance(popup, Gtk.MenuShell):
            return

        item = Gtk.SeparatorMenuItem()
        item.show()
        popup.append(item)

        item = Gtk.MenuItem.new_with_mnemonic(_("_Join Lines"))
        item.set_sensitive(self.view.get_editable())
        item.show()
        item.connect('activate', lambda i: self.join_lines())
        popup.append(item)

        item = Gtk.MenuItem.new_with_mnemonic(_('_Split Lines'))
        item.set_sensitive(self.view.get_editable())
        item.show()
        item.connect('activate', lambda i: self.split_lines())
        popup.append(item)

    def join_lines(self):
        doc = self.view.get_buffer()
        if doc is None:
            return

        # If there is a selection use it, otherwise join the
        # next line
        try:
            start, end = doc.get_selection_bounds()
        except ValueError:
            start = doc.get_iter_at_mark(doc.get_insert())
            end = start.copy()
            end.forward_line()

        doc.join_lines(start, end)

    def split_lines(self):
        doc = self.view.get_buffer()
        if doc is None:
            return

        width = self.view.get_right_margin_position()
        tabwidth = self.view.get_tab_width()

        doc.begin_user_action()

        try:
            # get selection bounds
            start, end = doc.get_selection_bounds()

            # measure indent until selection start
            indent_iter = start.copy()
            indent_iter.set_line_offset(0)
            indent = ''
            while indent_iter.get_offset() != start.get_offset():
                if indent_iter.get_char() == '\t':
                    indent = indent + '\t'
                else:
                    indent = indent + ' '
                indent_iter.forward_char()
        except ValueError:
            # select from start to line end
            start = doc.get_iter_at_mark(doc.get_insert())
            start.set_line_offset(0)
            end = start.copy()
            if not end.ends_line():
                end.forward_to_line_end()

            # measure indent of line
            indent_iter = start.copy()
            indent = ''
            while indent_iter.get_char() in (' ', '\t'):
                indent = indent + indent_iter.get_char()
                indent_iter.forward_char()

        end_mark = doc.create_mark(None, end)

        # ignore first word
        previous_word_end = start.copy()
        forward_to_word_start(previous_word_end)
        forward_to_word_end(previous_word_end)

        while 1:
            current_word_start = previous_word_end.copy()
            forward_to_word_start(current_word_start)

            current_word_end = current_word_start.copy()
            forward_to_word_end(current_word_end)

            if (not current_word_end.is_end()) and \
               doc.get_iter_at_mark(end_mark).compare(current_word_end) >= 0:

                word_length = current_word_end.get_offset() - \
                              current_word_start.get_offset()

                doc.delete(previous_word_end, current_word_start)

                line_offset = self.view.get_visual_column(current_word_start)
                if line_offset + word_length > width - 1:
                    doc.insert(current_word_start, '\n' + indent)
                else:
                    doc.insert(current_word_start, ' ')

                previous_word_end = current_word_start.copy()
                previous_word_end.forward_chars(word_length)
            else:
                break

        doc.delete_mark(end_mark)
        doc.end_user_action()


def forward_to_word_start(text_iter):
    char = text_iter.get_char()
    while not text_iter.is_end() and char in (' ', '\t', '\n', '\r'):
        text_iter.forward_char()
        char = text_iter.get_char()


def forward_to_word_end(text_iter):
    char = text_iter.get_char()
    while not text_iter.is_end() and not (char in (' ', '\t', '\n', '\r')):
        text_iter.forward_char()
        char = text_iter.get_char()

# ex:ts=4:et:
