import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Lang;

// A second, low-rate timer driving animation phase, independent of
// SwimController's 1 Hz game clock. SwimView starts and stops it on state
// changes so idle screens don't keep waking the CPU across what can be an
// hour-long swim.
class AnimationClock {

    const INTERVAL_MS = 200;
    const PHASE_STEP = 0.35; // radians per tick

    private var _timer as Timer.Timer?;
    private var _phase as Float;

    function initialize() {
        _phase = 0.0;
    }

    function start() as Void {
        if (_timer != null) {
            return;
        }
        _timer = new Timer.Timer();
        (_timer as Timer.Timer).start(method(:onTick), INTERVAL_MS, true);
    }

    function stop() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        _phase += PHASE_STEP;
        WatchUi.requestUpdate();
    }

    function phase() as Float {
        return _phase;
    }
}
