import Toybox.Position;
import Toybox.WatchUi;
import Toybox.Lang;

// Live GPS fix quality, so the swimmer can watch a fix land on the home
// screen before wading in. Location events are enabled once at app startup.
class GpsStatus {

    private var _accuracy as Number;

    function initialize() {
        _accuracy = Position.QUALITY_NOT_AVAILABLE;
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onPosition(info as Position.Info) as Void {
        _accuracy = info.accuracy;
        WatchUi.requestUpdate();
    }

    function accuracy() as Number {
        return _accuracy;
    }
}
