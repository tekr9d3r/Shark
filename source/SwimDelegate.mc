import Toybox.Lang;
import Toybox.WatchUi;

class SwimDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // SELECT does the obvious thing for whatever is on screen; mid-swim that
    // is pause.
    function onSelect() as Boolean {
        var controller = getApp().controller;
        var s = controller.state;

        if (s == SwimConstants.STATE_HOME) {
            controller.homeConfirm();
        } else if (s == SwimConstants.STATE_INSTRUCTIONS) {
            controller.instructionsAdvance();
        } else if (s == SwimConstants.STATE_SWIM || s == SwimConstants.STATE_PAUSED) {
            controller.togglePause();
        } else {
            controller.returnHome();
        }
        return true;
    }

    function onNextPage() as Boolean {
        return move(1);
    }

    function onPreviousPage() as Boolean {
        return move(-1);
    }

    private function move(delta as Number) as Boolean {
        var controller = getApp().controller;
        var s = controller.state;

        if (s == SwimConstants.STATE_HOME) {
            controller.homeMove(delta);
            return true;
        } else if (s == SwimConstants.STATE_INSTRUCTIONS) {
            controller.instructionsMove(delta);
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        return openActivityMenu();
    }

    // BACK on the root view quits the app by default, which mid-swim would
    // silently abandon the recording. Route it to the in-activity menu so
    // leaving is always a deliberate choice between keeping and deleting.
    function onBack() as Boolean {
        return openActivityMenu();
    }

    private function openActivityMenu() as Boolean {
        var controller = getApp().controller;
        var s = controller.state;

        if (s == SwimConstants.STATE_INSTRUCTIONS || s == SwimConstants.STATE_RESULT) {
            controller.returnHome();
            return true;
        }
        if (s == SwimConstants.STATE_HOME) {
            return false; // fall through to the default quit
        }

        controller.ensurePausedForMenu();
        WatchUi.pushView(new Rez.Menus.ActivityMenu(), new ActivityMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}
