import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SharkApp extends Application.AppBase {

    var controller as SwimController;

    function initialize() {
        AppBase.initialize();
        controller = new SwimController();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new SwimView(), new SwimDelegate() ];
    }
}

function getApp() as SharkApp {
    return Application.getApp() as SharkApp;
}
