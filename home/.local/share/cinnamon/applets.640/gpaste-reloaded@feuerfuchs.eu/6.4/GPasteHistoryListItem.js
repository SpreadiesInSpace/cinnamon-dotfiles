const PopupMenu = imports.ui.popupMenu;

// ------------------------------------------------------------------------------------------------------

class GPasteHistoryListItem extends PopupMenu.PopupMenuItem {
    constructor(applet, name) {
        super(name, {});

        this._applet   = applet;
        this._histName = name;
    }

    //
    // Overrides
    // ---------------------------------------------------------------------------------

    /*
     * Select history item
     */
    activate(event) {
        this._applet.selectHistory(this._histName);
        this._applet.contextMenu.close(true);
    }
};
