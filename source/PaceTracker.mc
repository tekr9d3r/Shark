import Toybox.Lang;

// Live pace, smoothed. Swim distance arrives in bursts - a pool length lands
// as one 25 m jump at the wall and nothing in between, and open-water GPS
// updates in ragged clumps whenever the wrist clears the surface - so the
// raw per-tick speed is either zero or enormous and is useless to display.
//
// An exponential moving average over a ~25 s window turns both patterns into
// a number a swimmer can actually pace off: one that settles within about a
// length and doesn't flicker between strokes. Not a rolling window buffer,
// because this runs once a second for the length of a 5 km swim and a single
// float is cheaper than a queue on a 128 KB device.
class PaceTracker {

    const TAU_SECONDS = 25.0;
    const MIN_SPEED = 0.05; // below this the swimmer is treated as stopped

    private var _speed as Float;
    private var _lastMeters as Float;
    private var _seeded as Boolean;

    function initialize() {
        _speed = 0.0;
        _lastMeters = 0.0;
        _seeded = false;
    }

    function update(meters as Float, dt as Float) as Void {
        if (!_seeded) {
            _lastMeters = meters;
            _seeded = true;
            return;
        }
        if (dt <= 0.0) {
            return;
        }
        var instant = (meters - _lastMeters) / dt;
        if (instant < 0.0) {
            instant = 0.0;
        }
        _lastMeters = meters;

        var alpha = dt / TAU_SECONDS;
        if (alpha > 1.0) {
            alpha = 1.0;
        }
        _speed += (instant - _speed) * alpha;
    }

    function speed() as Float {
        return _speed;
    }

    function isMoving() as Boolean {
        return (_speed > MIN_SPEED);
    }
}
