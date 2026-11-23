import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.System;

// The state machine and everything the screens read from:
//
//   HOME -> INSTRUCTIONS -> HOME
//   HOME -> SWIM (scent window, then the hunt)
//   SWIM <-> PAUSED
//   SWIM -> RESULT  (eaten, or ended from the menu)
//
// The simulation lives in SwimModel and the distance in DistanceSource; this
// class owns the clock, the transitions, and the side effects (recording,
// haptics) that neither of those is allowed to touch.
class SwimController {

    const TICK_MS = 1000;

    var state as Number;

    private var _timer as Timer.Timer?;
    private var _model as SwimModel?;
    private var _distance as DistanceSource?;
    private var _pace as PaceTracker;
    private var _recorder as ActivityRecorder;
    private var _feedback as Feedback;
    private var _gps as GpsStatus;

    private var _homeIndex as Number;
    private var _instructionsPage as Number;

    private var _endReason as Number;
    // Frozen the moment the swim ends: once the session is saved,
    // Activity.getActivityInfo() stops reporting.
    private var _finalMeters as Float;
    private var _finalSeconds as Float;
    private var _finalHuntSeconds as Float;

    function initialize() {
        state = SwimConstants.STATE_HOME;
        _homeIndex = SwimConstants.HOME_START;
        _instructionsPage = 0;

        _pace = new PaceTracker();
        _recorder = new ActivityRecorder();
        _feedback = new Feedback();
        _gps = new GpsStatus();

        _endReason = SwimConstants.REASON_NONE;
        _finalMeters = 0.0;
        _finalSeconds = 0.0;
        _finalHuntSeconds = 0.0;
    }

    // --- home ------------------------------------------------------------

    function homeIndex() as Number {
        return _homeIndex;
    }

    function homeMove(delta as Number) as Void {
        var count = SwimConstants.HOME_OPTION_COUNT;
        _homeIndex = ((_homeIndex + delta) + count) % count;
        WatchUi.requestUpdate();
    }

    // START goes straight into the swim - there is nothing to set up.
    function homeConfirm() as Void {
        if (_homeIndex == SwimConstants.HOME_START) {
            startSwim();
            return;
        } else if (_homeIndex == SwimConstants.HOME_HOW_TO) {
            _instructionsPage = 0;
            state = SwimConstants.STATE_INSTRUCTIONS;
        } else {
            System.exit();
        }
        WatchUi.requestUpdate();
    }

    function returnHome() as Void {
        state = SwimConstants.STATE_HOME;
        _homeIndex = SwimConstants.HOME_START;
        WatchUi.requestUpdate();
    }

    // --- instructions ----------------------------------------------------

    function instructionsPage() as Number {
        return _instructionsPage;
    }

    function instructionsMove(delta as Number) as Void {
        var next = _instructionsPage + delta;
        if (next < 0) {
            next = 0;
        } else if (next >= SwimConstants.INSTRUCTIONS_PAGE_COUNT) {
            next = SwimConstants.INSTRUCTIONS_PAGE_COUNT - 1;
        }
        _instructionsPage = next;
        WatchUi.requestUpdate();
    }

    function instructionsAdvance() as Void {
        if (_instructionsPage >= SwimConstants.INSTRUCTIONS_PAGE_COUNT - 1) {
            state = SwimConstants.STATE_HOME;
        } else {
            _instructionsPage += 1;
        }
        WatchUi.requestUpdate();
    }

    // --- the swim --------------------------------------------------------

    private function startSwim() as Void {
        _model = new SwimModel();
        _distance = new DistanceSource();
        _pace = new PaceTracker();
        _endReason = SwimConstants.REASON_NONE;
        _finalMeters = 0.0;
        _finalSeconds = 0.0;
        _finalHuntSeconds = 0.0;

        _recorder.start();
        state = SwimConstants.STATE_SWIM;
        _feedback.onSwimStart();

        startTimer();
        WatchUi.requestUpdate();
    }

    private function startTimer() as Void {
        if (_timer != null) {
            return;
        }
        _timer = new Timer.Timer();
        (_timer as Timer.Timer).start(method(:onTick), TICK_MS, true);
    }

    private function stopTimer() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        if (state != SwimConstants.STATE_SWIM) {
            return;
        }
        var model = _model;
        var distance = _distance;
        if (model == null || distance == null) {
            return;
        }

        var dt = 1.0;
        var meters = distance.meters();
        _pace.update(meters, dt);

        var released = model.tick(meters, _pace.speed(), dt);
        if (released) {
            _feedback.onSharkReleased(model.headStartMeters);
        }

        if (model.hunting) {
            _recorder.recordGap(model.gap());
        }

        if (model.isOver()) {
            finish(model.endReason);
        } else if (model.hunting && !released) {
            _feedback.onProximityTick(model.gap(), model.headStartMeters);
        }

        WatchUi.requestUpdate();
    }

    // --- pause -----------------------------------------------------------

    function togglePause() as Void {
        if (state == SwimConstants.STATE_PAUSED) {
            state = SwimConstants.STATE_SWIM;
            startTimer();
        } else if (state == SwimConstants.STATE_SWIM) {
            state = SwimConstants.STATE_PAUSED;
            stopTimer();
            _feedback.onPause();
        }
        WatchUi.requestUpdate();
    }

    // The in-activity menu pauses unconditionally on open and only resumes
    // what it actually paused.
    function ensurePausedForMenu() as Void {
        if (state == SwimConstants.STATE_SWIM) {
            togglePause();
        }
    }

    function resumeFromMenu() as Void {
        if (state == SwimConstants.STATE_PAUSED) {
            togglePause();
        }
    }

    // --- ending ----------------------------------------------------------

    private function finish(reason as Number) as Void {
        stopTimer();
        _endReason = reason;

        var model = _model;
        if (model != null) {
            _finalMeters = model.swimmerMeters;
            _finalSeconds = model.elapsed;
            _finalHuntSeconds = model.huntSeconds();
        }
        _recorder.recordSurvived(_finalHuntSeconds);
        _recorder.stop();

        state = SwimConstants.STATE_RESULT;
        if (reason == SwimConstants.REASON_EATEN) {
            _feedback.onEaten();
        }
        WatchUi.requestUpdate();
    }

    // "End Activity" - stops here and keeps the swim.
    function endActivityAndSave() as Void {
        finish(SwimConstants.REASON_STOPPED);
    }

    // "Delete Activity" - throws the recording away and goes straight home.
    function endActivityAndDiscard() as Void {
        stopTimer();
        _recorder.discard();
        _model = null;
        _distance = null;
        _endReason = SwimConstants.REASON_NONE;
        _finalMeters = 0.0;
        _finalSeconds = 0.0;
        _finalHuntSeconds = 0.0;
        returnHome();
    }

    // --- readouts for the screens ----------------------------------------

    function model() as SwimModel? {
        return _model;
    }

    function currentPaceString() as String {
        return Utils.speedToPaceString(_pace.speed());
    }

    function endReason() as Number {
        return _endReason;
    }

    function finalMeters() as Float {
        return _finalMeters;
    }

    function finalSeconds() as Float {
        return _finalSeconds;
    }

    function finalHuntSeconds() as Float {
        return _finalHuntSeconds;
    }

    function averagePaceString() as String {
        if (_finalSeconds <= 0.0 || _finalMeters <= 0.0) {
            return "--:--";
        }
        return Utils.speedToPaceString(_finalMeters / _finalSeconds);
    }

    function gpsAccuracy() as Number {
        return _gps.accuracy();
    }
}
