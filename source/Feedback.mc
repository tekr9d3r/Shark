import Toybox.Attention;
import Toybox.Lang;

// Every tone and vibration in the game, in one place.
//
// A swimmer's face is in the water and their eyes are behind a fogged goggle
// for minutes at a time, so vibration is not the secondary channel here, it
// is the *only* channel. The vocabulary is kept small enough to learn in one
// swim:
//
//   one short pulse         swim started - the shark is picking up your scent
//   three hard knocks       the shark is in the water
//   one pulse, repeating    it just took another bite out of the gap
//   heartbeat, quickening   it is on you
//   one long buzz           eaten - swim over
//
// Silence is load-bearing: through the whole cruising stage the watch says
// nothing at all, so the first closing pulse carries real information.
class Feedback {

    // The closing-stage pulse fires once per this fraction of the head start
    // the shark claws back, so the rhythm feels the same for every pace.
    const CLOSING_PULSE_FRACTION = 0.1;

    private var _hasVibrate as Boolean;
    private var _hasTone as Boolean;
    private var _lastStage as Number;
    private var _lastPulseGap as Float;
    private var _pulseStepMeters as Float;

    function initialize() {
        _hasVibrate = (Attention has :vibrate);
        _hasTone = (Attention has :playTone);
        _lastStage = SwimConstants.DANGER_STAGE_CRUISE;
        _lastPulseGap = 0.0;
        _pulseStepMeters = 4.0;
    }

    function onSwimStart() as Void {
        _lastStage = SwimConstants.DANGER_STAGE_CRUISE;
        beep(Attention.TONE_START);
        buzz([new Attention.VibeProfile(70, 300)]);
    }

    // The shark is released. Three heavy knocks, unlike anything else in the
    // vocabulary, because it marks the moment the swim becomes a chase.
    function onSharkReleased(headStartMeters as Float) as Void {
        _lastStage = SwimConstants.DANGER_STAGE_CRUISE;
        _lastPulseGap = headStartMeters;
        _pulseStepMeters = headStartMeters * CLOSING_PULSE_FRACTION;
        if (_pulseStepMeters < 2.0) {
            _pulseStepMeters = 2.0;
        }
        beep(Attention.TONE_ALERT_LO);
        buzz([
            new Attention.VibeProfile(100, 220),
            new Attention.VibeProfile(0, 140),
            new Attention.VibeProfile(100, 220),
            new Attention.VibeProfile(0, 140),
            new Attention.VibeProfile(100, 220)
        ]);
    }

    // Called every hunting tick. Stage boundaries come from SwimConstants so
    // the haptics and the screen always agree.
    function onProximityTick(gap as Float, headStart as Float) as Void {
        var fraction = SwimConstants.dangerFraction(gap, headStart);
        var stage = SwimConstants.dangerStage(fraction);

        if (stage != _lastStage) {
            if (stage == SwimConstants.DANGER_STAGE_CLOSING) {
                // Baseline the pulse grid where the stage was entered, so
                // crossing the line isn't itself a pulse.
                _lastPulseGap = gap;
            } else if (stage == SwimConstants.DANGER_STAGE_JAWS) {
                beep(Attention.TONE_ALERT_HI);
            }
            _lastStage = stage;
        }

        if (stage == SwimConstants.DANGER_STAGE_CLOSING) {
            if ((_lastPulseGap - gap) >= _pulseStepMeters) {
                _lastPulseGap = gap;
                buzz([new Attention.VibeProfile(60, 170)]);
            } else if (gap > _lastPulseGap) {
                // You pulled away - re-arm from here rather than owing the
                // shark the metres you just won back.
                _lastPulseGap = gap;
            }
        } else if (stage == SwimConstants.DANGER_STAGE_JAWS) {
            heartbeat(fraction);
        }
    }

    // Two pulses a second, and the pause between them tightens as the shark
    // closes the last few metres.
    private function heartbeat(fraction as Float) as Void {
        var t = (fraction - SwimConstants.DANGER_JAWS_THRESHOLD) / (1.0 - SwimConstants.DANGER_JAWS_THRESHOLD);
        if (t < 0.0) {
            t = 0.0;
        } else if (t > 1.0) {
            t = 1.0;
        }
        var pause = (120.0 - 70.0 * t).toNumber();
        buzz([
            new Attention.VibeProfile(100, 130),
            new Attention.VibeProfile(0, pause),
            new Attention.VibeProfile(100, 130)
        ]);
    }

    function onEaten() as Void {
        beep(Attention.TONE_FAILURE);
        buzz([
            new Attention.VibeProfile(100, 700),
            new Attention.VibeProfile(0, 120),
            new Attention.VibeProfile(100, 400)
        ]);
    }

    function onPause() as Void {
        buzz([new Attention.VibeProfile(40, 220)]);
    }

    private function buzz(profiles as Array<Attention.VibeProfile>) as Void {
        if (!_hasVibrate) {
            return;
        }
        try {
            Attention.vibrate(profiles);
        } catch (ex) {
        }
    }

    private function beep(t as Attention.Tone) as Void {
        if (!_hasTone) {
            return;
        }
        try {
            Attention.playTone(t);
        } catch (ex) {
        }
    }
}
