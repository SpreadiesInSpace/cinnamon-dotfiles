const St        = imports.gi.St;
const PopupMenu = imports.ui.popupMenu;
const Pango     = imports.gi.Pango;
const Clutter   = imports.gi.Clutter;

// ------------------------------------------------------------------------------------------------------

class GPasteHistoryItem extends PopupMenu.PopupBaseMenuItem {
    constructor(applet) {
        super();

        this._applet = applet;

        //
        // Label

        this.label = new St.Label({ text: '' });
        this.label.clutter_text.set_ellipsize(Pango.EllipsizeMode.END);
        this.addActor(this.label);

        this.setTextLength();
        this._settingsChangedID = this._applet.clientSettings.connect('changed::element-size', () => this.setTextLength());

        //
        // Delete button

        const iconDelete = new St.Icon({
            icon_name:   'edit-delete',
            icon_type:   St.IconType.SYMBOLIC,
            style_class: 'popup-menu-icon'
        });
        this.deleteButton = new St.Button({ child: iconDelete });
        this.deleteButton.connect('clicked', () => this.remove());
        this.addActor(this.deleteButton, { expand: false, span: -1, align: St.Align.END });

        //
        //

        this.actor.connect('destroy', () => this._onDestroy());
    }

    /*
     * Override key press event
     */
    _onKeyPressEvent(actor, event) {
        let symbol = event.get_key_symbol();

        if (symbol == Clutter.KEY_space || symbol == Clutter.KEY_Return) {
            this.activate(event);
            return true;
        } else if (symbol == Clutter.KEY_Delete || symbol == Clutter.KEY_BackSpace) {
            this.remove();
            return true;
        }

        return false;
    }

    /*
     * Set max text length using GPaste's setting
     */
    setTextLength() {
        this.label.clutter_text.set_max_length(this._applet.clientSettings.get_element_size());
    }

    /*
     * Set specified index and get respective history item's content
     */
    setIndex(index) {
        this._index = index;

        if (index != -1) {
            this._applet.client.get_element_at_index(index, (client, result) => {
                let item = client.get_element_at_index_finish(result);
                this._uuid = item.get_uuid();
                this.label.set_text(item.get_value().replace(/[\t\n\r]/g, ''));
            });

            this.actor.show();
        }
        else {
            this.actor.hide();
        }
    }

    /*
     * Refresh history item's content
     */
    refresh() {
        this._applet.client.get_element_at_index(this._index, (client, result) => {
            let item = client.get_element_at_index_finish(result);
            this._uuid = item.get_uuid();
            this.label.set_text(item.get_value().replace(/[\t\n\r]/g, ''));
        });
    }
    
    /*
     * Remove history item
     */
    remove() {
        this._applet.client.delete(this._uuid, null);
    }

    //
    // Events
    // ---------------------------------------------------------------------------------

    /*
     * History item has been removed, disconnect bindings
     */
    _onDestroy() {
        this._applet.clientSettings.disconnect(this._settingsChangedID);
    }

    //
    // Overrides
    // ---------------------------------------------------------------------------------

    /*
     * Select history item
     */
    activate(event) {
        this._applet.client.select(this._uuid, null);
        this._applet.menu.toggle();
    }
};
