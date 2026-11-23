import Toybox.Activity;
import Toybox.Lang;

// The swimmer's distance: open-water GPS, read off the recording session.
//
// Monotonic clamping sits on top of the raw reading. Wrist-under-water means
// the fix drops out constantly and can revise distance downward when it
// comes back. Distance is allowed to stand still through a bad patch but
// never to go backwards, which would hand the swimmer's metres to the shark
// for nothing.
class DistanceSource {

    private var _baseline as Float?;
    private var _measured as Float;

    function initialize() {
        _baseline = null;
        _measured = 0.0;
    }

    function meters() as Float {
        var info = Activity.getActivityInfo();
        if (info != null && info.elapsedDistance != null) {
            var raw = info.elapsedDistance as Float;
            // The session may already have a metre or two on it by the first
            // tick; zero the swim against that first reading.
            if (_baseline == null) {
                _baseline = raw;
            }
            var d = raw - (_baseline as Float);
            if (d > _measured) {
                _measured = d;
            }
        }
        return _measured;
    }
}
