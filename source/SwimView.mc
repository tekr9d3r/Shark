import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// One persistent view that redraws differently per state. Geometry lives in
// ScreenMetrics/HudLayout and content in one module per state, so round vs.
// rectangle and resolution scaling are solved once rather than per screen.
class SwimView extends WatchUi.View {

    private var _animClock as AnimationClock;
    private var _lastState as Number;

    function initialize() {
        View.initialize();
        _animClock = new AnimationClock();
        _lastState = -1;
    }

    function onShow() as Void {
        syncAnimationClock(getApp().controller.state);
    }

    function onHide() as Void {
        _animClock.stop();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Palette.SKY);
        dc.clear();

        var controller = getApp().controller;
        var metrics = new ScreenMetrics(dc);
        var layout = new HudLayout(metrics);
        var state = controller.state;

        if (state != _lastState) {
            syncAnimationClock(state);
            _lastState = state;
        }

        var phase = _animClock.phase();
        if (state == SwimConstants.STATE_HOME) {
            HomeScreen.draw(dc, metrics, layout, controller, phase);
        } else if (state == SwimConstants.STATE_INSTRUCTIONS) {
            InstructionsScreen.draw(dc, metrics, layout, controller, phase);
        } else if (state == SwimConstants.STATE_SWIM) {
            SwimScreen.draw(dc, metrics, layout, controller, phase);
        } else if (state == SwimConstants.STATE_PAUSED) {
            PausedScreen.draw(dc, metrics, layout, controller);
        } else {
            ResultScreen.draw(dc, metrics, layout, controller, phase);
        }
    }

    // Animation is stopped while paused, so a timer isn't waking the CPU
    // five times a second while the swimmer stands at a buoy. The
    // result screen keeps animating: by the time it is reached the session
    // has already been stopped and saved, so there is no recording left to
    // protect.
    private function syncAnimationClock(state as Number) as Void {
        if (state == SwimConstants.STATE_PAUSED) {
            _animClock.stop();
        } else {
            _animClock.start();
        }
    }
}
