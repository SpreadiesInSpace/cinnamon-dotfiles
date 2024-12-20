const ModalDialog = imports.ui.modalDialog;
const St          = imports.gi.St;
const GObject     = imports.gi.GObject;

const _           = require('./__init__')._;

// ------------------------------------------------------------------------------------------------------
var GPasteNotInstalledDialog = GObject.registerClass(
class GPasteNotInstalledDialog extends ModalDialog.ModalDialog {
    _init(callback) {
        super._init({ styleClass: 'gpaste__not-found-dialog' });

        this.contentLayout.add(new St.Label({ text: _("GPaste is not installed. Please install the necessary packages and then restart Cinnamon for this applet to start working.") }));
        this.contentLayout.add_style_class_name('gpaste__not-found-dialog__content');

        this.setButtons([
            {
                label: _("OK"),
                action: () => this._onOK()
            }
        ]);
    }

    //
    // Events
    // ---------------------------------------------------------------------------------

    /*
     * The OK button was pressed
     */
    _onOK() {
        this.close(global.get_current_time());
    }
});
