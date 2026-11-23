import Toybox.Lang;
import Toybox.Position;

module SwimConstants {

    // --- app states -------------------------------------------------------
    const STATE_HOME = 0;
    const STATE_INSTRUCTIONS = 1;
    const STATE_SWIM = 2;
    const STATE_PAUSED = 3;
    const STATE_RESULT = 4;

    // --- home menu rows, top to bottom ------------------------------------
    const HOME_START = 0;
    const HOME_HOW_TO = 1;
    const HOME_EXIT = 2;
    const HOME_OPTION_COUNT = 3;

    const INSTRUCTIONS_PAGE_COUNT = 3;

    // --- the hunt ---------------------------------------------------------
    // No distance, no target pace. The swim opens with a short scent window
    // in which the shark is not yet in the water: it is reading your easy
    // pace. Then it is released a fixed number of *seconds of your own
    // swimming* behind you and hunts at a margin above your pace, so the
    // same tuning works for a 1:40 swimmer and a 3:00 one.
    //
    // While hunting, its idea of your pace drifts toward your live pace with
    // a long time constant. Swim harder and you gain on it for a few
    // minutes before it adapts - so building the pace buys time but never
    // buys safety, which is exactly the shape of a warm-up.
    //
    // Worked through (see docs/design.md), holding a steady pace after the
    // scent window gets you caught at roughly:
    //   same easy pace   ~6.5 min total
    //   5% faster        ~7.5 min
    //   10% faster       ~9.5 min
    //   20% faster       ~13.5 min
    const SCENT_SECONDS = 90;
    // The first part of the scent window is ignored when reading your pace:
    // that is wading in, getting a GPS fix and finding a rhythm.
    const SCENT_SETTLE_SECONDS = 30;

    const HEAD_START_SECONDS = 50.0;  // released this many seconds of your swimming behind
    const HUNT_MARGIN = 0.17;         // shark swims 17% faster than its read of your pace
    const ADAPT_TAU_SECONDS = 600.0;  // how slowly it re-reads your pace

    // Past this point the shark starts getting hungry, so even a swimmer who
    // keeps building can't stay ahead forever and the session stays a
    // warm-up rather than a workout.
    const FRENZY_AFTER_SECONDS = 720.0;
    const FRENZY_MARGIN_PER_MINUTE = 0.08;

    // Plausible open-water swim speeds, in m/s. A floor keeps a slow GPS fix
    // or a swimmer standing in the shallows from producing a shark that
    // barely moves; a ceiling throws away a GPS jump.
    const SPEED_FLOOR = 0.5;   // 3:20 /100 m
    const SPEED_CEILING = 2.0; // 0:50 /100 m

    // Gap at which the shark has you.
    const CATCH_THRESHOLD_METERS = 2.0;

    // Why the swim ended.
    const REASON_NONE = 0;
    const REASON_EATEN = 1;    // the shark closed the gap
    const REASON_STOPPED = 2;  // ended by hand from the in-activity menu

    // --- danger staging ---------------------------------------------------
    // Shared by SwimScreen (water colour, teeth, shark size and depth) and
    // Feedback (haptics) so the picture and the buzz never disagree about
    // how close the shark is. Thresholds are fractions of the way from the
    // head start down to the catch.
    const DANGER_STAGE_CRUISE = 0;
    const DANGER_STAGE_CLOSING = 1;
    const DANGER_STAGE_JAWS = 2;

    const DANGER_CLOSING_THRESHOLD = 0.5;
    const DANGER_JAWS_THRESHOLD = 0.82;

    // 0.0 (gap at or beyond the head start) .. 1.0 (about to be bitten).
    function dangerFraction(gap as Float, headStart as Float) as Float {
        var span = headStart - CATCH_THRESHOLD_METERS;
        if (span <= 0.0) {
            return 1.0;
        }
        var g = gap;
        if (g > headStart) {
            g = headStart;
        } else if (g < CATCH_THRESHOLD_METERS) {
            g = CATCH_THRESHOLD_METERS;
        }
        return 1.0 - ((g - CATCH_THRESHOLD_METERS) / span);
    }

    function dangerStage(fraction as Float) as Number {
        if (fraction >= DANGER_JAWS_THRESHOLD) {
            return DANGER_STAGE_JAWS;
        } else if (fraction >= DANGER_CLOSING_THRESHOLD) {
            return DANGER_STAGE_CLOSING;
        }
        return DANGER_STAGE_CRUISE;
    }

    // --- GPS status, shown on the home screen so the swimmer can see a fix
    // land before wading in (informational only - never blocks the start).
    const GPS_TIER_SEARCHING = 0;
    const GPS_TIER_WEAK = 1;
    const GPS_TIER_READY = 2;

    function gpsTier(accuracy as Number) as Number {
        if (accuracy >= Position.QUALITY_USABLE) {
            return GPS_TIER_READY;
        } else if (accuracy == Position.QUALITY_POOR) {
            return GPS_TIER_WEAK;
        }
        return GPS_TIER_SEARCHING;
    }

    function clampSpeed(speed as Float) as Float {
        if (speed < SPEED_FLOOR) {
            return SPEED_FLOOR;
        } else if (speed > SPEED_CEILING) {
            return SPEED_CEILING;
        }
        return speed;
    }
}
