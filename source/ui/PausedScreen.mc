import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Everything is frozen here - the game clock is stopped, so the shark holds
// its position and the gap you paused with is the gap you resume with. A
// swimmer stopping at a buoy or clearing a goggle should not be fed to the
// shark for it.
//
// The screen still shows where the hunt stood, so the decision to resume is
// made knowing what you are resuming into. The fangs hold the length they
// had, but stay still: the animation clock is off while paused.
module PausedScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as SwimController) as Void {
        var bands = Palette.WATER_CRUISE;
        dc.setColor(bands[3] as Number, bands[3] as Number);
        dc.fillRectangle(0, 0, metrics.width, metrics.height);

        var title = WatchUi.loadResource(Rez.Strings.StatePaused) as String;
        Hud.drawShadowText(dc, metrics.centerX, layout.titleY, metrics.fontFor(3), title, Palette.BONE, Palette.BLOOD_DARK);

        var model = controller.model();
        var bite = 0.1;
        if (model != null) {
            drawStats(dc, metrics, layout, model);
            bite = model.hunting ? 0.15 + 0.85 * model.danger() : 0.1;
        }

        dc.setColor(Palette.MUTED, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.hintY, 0,
            WatchUi.loadResource(Rez.Strings.HintResume) as String,
            (metrics.width * 0.5).toNumber());

        Jaws.drawFrame(dc, metrics, bite, 3, 0.0);
    }

    function drawStats(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, model as SwimModel) as Void {
        var bandTop = layout.stageTop;
        var bandBottom = layout.stageBottom;
        var labelFont = metrics.fontFor(0);
        var labelH = dc.getFontHeight(labelFont);
        var rowH = dc.getFontHeight(metrics.fontFor(1));

        // Hero: the gap once hunting, the countdown before - whichever
        // decides whether resuming is comfortable or terrifying.
        var label;
        var numText;
        var unitText = "";
        if (model.hunting) {
            label = WatchUi.loadResource(Rez.Strings.PausedGapLabel) as String;
            numText = model.gap().format("%.0f");
            unitText = WatchUi.loadResource(Rez.Strings.UnitMeters) as String;
        } else {
            label = WatchUi.loadResource(Rez.Strings.SharkIn) as String;
            numText = Utils.formatClock(model.scentSecondsLeft().toFloat());
        }

        var available = (bandBottom - bandTop) - labelH - rowH;
        if (available < metrics.px(30)) {
            available = metrics.px(30);
        }
        var numFont = Hud.fitHeroFont(dc, metrics, numText,
            (metrics.width * 0.5).toNumber(), available);

        var y = bandTop;
        dc.setColor(Palette.BLOOD_BRIGHT, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, y, 0, label);
        y += labelH;

        Hud.drawNumberWithUnit(dc, metrics.centerX, y, numText, unitText,
            numFont, metrics.fontFor(1), Palette.BONE, Palette.MUTED);
        y += dc.getFontHeight(numFont);

        dc.setColor(Palette.PALE, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, y, 1,
            Utils.formatDistance(model.swimmerMeters) + "   " + Utils.formatClock(model.elapsed),
            (metrics.width * 0.6).toNumber());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
}
