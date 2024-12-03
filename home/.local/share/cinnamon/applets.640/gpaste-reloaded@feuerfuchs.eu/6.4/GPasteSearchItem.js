const St        = imports.gi.St;
const PopupMenu = imports.ui.popupMenu;

const _         = require('./__init__')._;

// ------------------------------------------------------------------------------------------------------

class GPasteSearchItem extends PopupMenu.PopupBaseMenuItem {
    constructor() {
        super({
            activate: false,
            reactive: true,
            hover:    true
        });

        //
        // Text field

        this.entry = new St.Entry({
            name:        'GPasteSearchEntry',
            hint_text:   _("Type to search..."),
            track_hover: true,
            can_focus:   true
        });
        this.addActor(this.entry, {
            expand: true,
            span:   -1
        });

        //
        // Search icon

        this.iconSearch = new St.Icon({
            icon_name: 'edit-find-symbolic'
        });
        this.entry.set_secondary_icon(this.iconSearch);

        //
        // Clear icon

        this.iconClear = new St.Icon({
            style_class: 'menu-search-entry-icon',
            icon_name:   'edit-clear-symbolic'
        });

        //
        //

        this.entry.clutter_text.connect('text-changed', this._onTextChanged.bind(this));

        //
        // Binding ID of the remove icon

        this.iconClearClickedID = 0;
    }

    /*
     * Reset search field
     */
    reset() {
        this.entry.set_text("");
    }

    /*
     * Get current input
     */
    getText() {
        return this.entry.get_text();
    }

    //
    // Events
    // ---------------------------------------------------------------------------------

    /*
     * Search string has changed
     */
    _onTextChanged(se, prop) {
        const text = this.entry.get_text();
        if (text !== '') {
            if (this.iconClearClickedID == 0) {
                this.entry.set_secondary_icon(this.iconClear);
                this.iconClearClickedID = this.entry.connect('secondary-icon-clicked', () => this.reset());
            }
        }
        else {
            if (this.iconClearClickedID != 0) {
                this.entry.set_secondary_icon(this.iconSearch);
                this.entry.disconnect(this.iconClearClickedID);
                this.iconClearClickedID = 0;
            }
        }
        this.emit('text-changed', text);
    }

    /*
     * The search field was selected via keyboard
     */
    _onKeyFocusIn(actor) {
        global.stage.set_key_focus(this.entry);
    }

    /*
     * The search field was selected via mouse hover
     */
    _onHoverChanged(actor) {
        global.stage.set_key_focus(this.entry);
    }
};
