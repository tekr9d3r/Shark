import Toybox.Lang;
import Toybox.WatchUi;

// The in-activity menu (MENU or BACK while swimming): Resume, End Activity,
// Delete Activity. Native Menu2 and Confirmation on purpose - a wet swimmer
// wanting to stop should meet the same list widget every Garmin app has.
class ActivityMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var controller = getApp().controller;

        if (id == :menu_resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            controller.resumeFromMenu();
        } else if (id == :menu_end_activity) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            controller.endActivityAndSave();
        } else if (id == :menu_delete_activity) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.DeleteConfirmMessage) as String);
            WatchUi.pushView(dialog, new DeleteConfirmDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    // The system has no idea the game is paused behind this menu, so BACK
    // has to resume explicitly.
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        getApp().controller.resumeFromMenu();
    }
}

class DeleteConfirmDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        var controller = getApp().controller;
        if (response == WatchUi.CONFIRM_YES) {
            WatchUi.popView(WatchUi.SLIDE_DOWN); // confirmation
            WatchUi.popView(WatchUi.SLIDE_DOWN); // menu
            controller.endActivityAndDiscard();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN); // back to the menu
        }
        return true;
    }
}
