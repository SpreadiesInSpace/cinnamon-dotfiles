# -*- coding: utf-8 -*-
# Copyright (c) 2007 - Steve Frécinaux <code@istique.net>
# Copyright (c) 2010 - Kenny Meyer <knny.myer@gmail.com>
# Licence: GPL2 or later

from gi.repository import GObject, Gtk, Gedit
import os.path
from gpdefs import GETTEXT_PACKAGE
from .store.session import Session


try:
    import gettext
    gettext.bindtextdomain('gedit-plugins')
    gettext.textdomain('gedit-plugins')
    _ = gettext.gettext
except:
    _ = lambda s: s

class SessionModel(Gtk.ListStore):
    OBJECT_COLUMN = 0
    NAME_COLUMN = 1
    N_COLUMNS = 2

    def __init__(self, store):
        super(SessionModel, self).__init__(GObject.TYPE_PYOBJECT, str)
        self.store = store
        for session in store:
            row = { self.OBJECT_COLUMN : session,
                    self.NAME_COLUMN: session.name }
            self.append(row.values())
        self.store.connect_after('session-added', self.on_session_added)
        self.store.connect('session-removed', self.on_session_removed)

    def on_session_added(self, store, session):
        row = { self.OBJECT_COLUMN : session,
                self.NAME_COLUMN: session.name }
        self.append(row.values())

    def on_session_removed(self, store, session):
        it = self.get_iter_first()
        if it is not None:
            while True:
                stored_session = self.get_value(it, self.OBJECT_COLUMN)
                if stored_session == session:
                    self.remove(it)
                    break
                it = self.iter_next(it)
                if not it:
                    break

class Dialog(object):
    UI_FILE = "sessionsaver.ui"

    def __init__(self, main_widget, datadir, parent_window = None):
        super(Dialog, self).__init__()

        if parent_window is None:
            parent_window = Gedit.App.get_default().get_active_window()
        self.parent = parent_window

        self.ui = Gtk.Builder()
        self.ui.set_translation_domain(GETTEXT_PACKAGE)

        self.ui.add_from_file(os.path.join(datadir, 'ui', self.UI_FILE))
        self.dialog = self.ui.get_object(main_widget)
        self.dialog.connect('delete-event', self.on_delete_event)

    def __getitem__(self, item):
        return self.ui.get_object(item)

    def on_delete_event(self, dialog, event):
        dialog.hide()
        return True

    def __del__(self):
        self.__class__._instance = None

    def run(self):
        self.dialog.set_transient_for(self.parent)
        self.dialog.show()

    def destroy(self):
        self.dialog.destroy()
        self.__del__()

class SaveSessionDialog(Dialog):
    def __init__(self, window, sessions, current_session, on_updated_sessions, data_dir):
        super(SaveSessionDialog, self).__init__('save-session-dialog',
                                                data_dir,
                                                window)

        self.NAME_COLUMN = 1
        self.on_updated_sessions = on_updated_sessions
        self.sessions = sessions

        model = SessionModel(sessions)

        self.combobox = self['session-name']
        self.combobox.set_model(model)
        self.combobox.set_entry_text_column(self.NAME_COLUMN)
        self.combobox.connect("changed", self.on_name_combo_changed)

        if current_session is None:
            self.on_name_combo_changed(self.combobox)
        else:
            self._set_combobox_active_by_name(current_session)

        self.dialog.connect('response', self.on_response)

    def _set_combobox_active_by_name(self, option_name):
        model = self.combobox.get_model()
        piter = model.get_iter_first()
        while piter is not None:
            if model.get_value(piter, self.NAME_COLUMN) == option_name:
                self.combobox.set_active_iter(piter)
                return True
            piter = model.iter_next(piter)
        return False

    def on_name_combo_changed(self, combo):
        name = combo.get_child().get_text()
        self['save_button'].set_sensitive(len(name) > 0)

    def on_response(self, dialog, response_id):
        if response_id == Gtk.ResponseType.OK:
            files = [doc.get_file().get_location()
                        for doc in self.parent.get_documents()
                        if doc.get_file().get_location() is not None]
            name = self.combobox.get_child().get_text()
            self.sessions.add(Session(name, files))
            self.sessions.save()
            self.on_updated_sessions()
        self.destroy()

class SessionManagerDialog(Dialog):
    def __init__(self, window, on_updated_sessions, on_load_session, sessions, data_dir):
        super(SessionManagerDialog, self).__init__('session-manager-dialog',
                                                data_dir,
                                                window)

        self.on_updated_sessions = on_updated_sessions
        self.on_load_session = on_load_session
        self.sessions = sessions
        self.sessions_updated = False

        model = SessionModel(sessions)

        self.view = self['session-view']
        self.view.set_model(model)

        renderer = Gtk.CellRendererText()
        column = Gtk.TreeViewColumn(_("Session Name"), renderer, text = model.NAME_COLUMN)
        self.view.append_column(column)

        handlers = {
            'on_close_button_clicked': self.on_close_button_clicked,
            'on_open_button_clicked': self.on_open_button_clicked,
            'on_delete_button_clicked': self.on_delete_button_clicked
        }
        self.ui.connect_signals(handlers)

    def on_delete_event(self, dialog, event):
        dialog.hide()
        self._should_save_sessions()
        return True

    def get_current_session(self):
        (model, selected) = self.view.get_selection().get_selected()
        if selected is None:
            return None
        return model.get_value(selected, SessionModel.OBJECT_COLUMN)

    def on_open_button_clicked(self, button):
        session = self.get_current_session()
        if session is not None:
            self.on_load_session(session)

    def on_delete_button_clicked(self, button):
        session = self.get_current_session()
        self.sessions.remove(session)
        self.sessions_updated = True

    def _should_save_sessions(self):
        if self.sessions_updated == False:
            return

        self.sessions.save()
        self.on_updated_sessions()
        self.sessions_updated = False

    def on_close_button_clicked(self, button):
        self._should_save_sessions()
        self.destroy()


# ex:ts=4:et:
