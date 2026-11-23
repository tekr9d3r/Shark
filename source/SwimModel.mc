import Toybox.Lang;

// The hunt, as a pure 1-D simulation along the swim. No rendering, no
// Attention, no Activity calls - the controller feeds it the swum distance,
// the smoothed live speed and a dt, and it answers with a gap and
// (eventually) a reason the swim ended.
//
// Two phases:
//
//   SCENT  the first SwimConstants.SCENT_SECONDS. No shark in the water yet;
//          the model is only reading your easy pace (ignoring the first
//          SCENT_SETTLE_SECONDS of wading in and finding a fix).
//
//   HUNT   the shark is released HEAD_START_SECONDS of *your* swimming
//          behind you and swims at its read of your pace plus a margin. That
//          read drifts toward your live pace over ~10 minutes, so a surge
//          gains you ground for a while and then the shark matches it.
//
// Positions are absolute metres along the swim, so the gap is just
// swimmer - shark.
class SwimModel {

    var swimmerMeters as Float;
    var sharkMeters as Float;
    var elapsed as Float;
    var endReason as Number;

    var hunting as Boolean;
    var headStartMeters as Float; // the gap at release; danger is measured against it
    var paceRead as Float;        // m/s - the shark's current read of your pace
    var sharkSpeed as Float;      // m/s

    private var _settleMeters as Float?;

    function initialize() {
        swimmerMeters = 0.0;
        sharkMeters = 0.0;
        elapsed = 0.0;
        endReason = SwimConstants.REASON_NONE;
        hunting = false;
        headStartMeters = 0.0;
        paceRead = 0.0;
        sharkSpeed = 0.0;
        _settleMeters = null;
    }

    // Metres between the shark's nose and the swimmer. Only meaningful once
    // hunting; during the scent window the shark has no position.
    function gap() as Float {
        if (!hunting) {
            return headStartMeters;
        }
        return swimmerMeters - sharkMeters;
    }

    // Seconds until the shark is released, for the scent-window countdown.
    function scentSecondsLeft() as Number {
        var left = SwimConstants.SCENT_SECONDS - elapsed.toNumber();
        return (left > 0) ? left : 0;
    }

    // 0.0 .. 1.0 through the scent window.
    function scentProgress() as Float {
        var p = elapsed / SwimConstants.SCENT_SECONDS.toFloat();
        return (p > 1.0) ? 1.0 : p;
    }

    function danger() as Float {
        if (!hunting) {
            return 0.0;
        }
        return SwimConstants.dangerFraction(gap(), headStartMeters);
    }

    function stage() as Number {
        return SwimConstants.dangerStage(danger());
    }

    // Seconds survived since the shark was released - the score.
    function huntSeconds() as Float {
        var t = elapsed - SwimConstants.SCENT_SECONDS.toFloat();
        return (t > 0.0) ? t : 0.0;
    }

    // `distanceMeters` is the swimmer's total so far (absolute, so a GPS
    // correction is absorbed rather than accumulating drift). `liveSpeed` is
    // the smoothed pace from PaceTracker. Returns true on the tick the
    // shark is released, so the controller can fire its buzz.
    function tick(distanceMeters as Float, liveSpeed as Float, dt as Float) as Boolean {
        if (endReason != SwimConstants.REASON_NONE) {
            return false;
        }
        elapsed += dt;
        swimmerMeters = distanceMeters;

        if (!hunting) {
            if (_settleMeters == null && elapsed >= SwimConstants.SCENT_SETTLE_SECONDS) {
                _settleMeters = swimmerMeters;
            }
            if (elapsed >= SwimConstants.SCENT_SECONDS) {
                release();
                return true;
            }
            return false;
        }

        // Re-read the swimmer's pace, slowly.
        var alpha = dt / SwimConstants.ADAPT_TAU_SECONDS;
        paceRead = SwimConstants.clampSpeed(paceRead + (liveSpeed - paceRead) * alpha);

        var margin = SwimConstants.HUNT_MARGIN;
        if (elapsed > SwimConstants.FRENZY_AFTER_SECONDS) {
            margin += (elapsed - SwimConstants.FRENZY_AFTER_SECONDS) / 60.0
                * SwimConstants.FRENZY_MARGIN_PER_MINUTE;
        }
        sharkSpeed = paceRead * (1.0 + margin);
        sharkMeters += sharkSpeed * dt;

        if (gap() <= SwimConstants.CATCH_THRESHOLD_METERS) {
            endReason = SwimConstants.REASON_EATEN;
        }
        return false;
    }

    function isOver() as Boolean {
        return endReason != SwimConstants.REASON_NONE;
    }

    // Easy pace = average speed over the settled part of the scent window.
    private function release() as Void {
        var settle = _settleMeters;
        var from = (settle != null) ? settle : 0.0;
        var window = (SwimConstants.SCENT_SECONDS - SwimConstants.SCENT_SETTLE_SECONDS).toFloat();
        paceRead = SwimConstants.clampSpeed((swimmerMeters - from) / window);

        headStartMeters = paceRead * SwimConstants.HEAD_START_SECONDS;
        sharkMeters = swimmerMeters - headStartMeters;
        sharkSpeed = paceRead * (1.0 + SwimConstants.HUNT_MARGIN);
        hunting = true;
    }
}
