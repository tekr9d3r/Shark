import Toybox.Graphics;
import Toybox.Math;
import Toybox.WatchUi;
import Toybox.Lang;

// The screen the whole game happens on, in two phases.
//
// SCENT (first 90 s): calm water, a fin circling far off, and a countdown to
// the release as the hero number. The fangs on the rim are short and slowly
// lengthen as the release approaches.
//
// HUNT: the waterline with you on the right and the shark behind you on the
// left, the space between drawn to scale; the gap in metres as the hero
// number. Everything escalates together off SwimConstants.dangerStage - the
// same staging the haptics use, so screen and buzz never disagree:
//   - the fangs lengthen continuously with danger, and chomp in the last stage;
//   - the water goes cold teal -> murky green -> blood;
//   - the shark grows and rises until its jaws are open at the surface;
//   - SWIM! blinks at the top.
module SwimScreen {

    const SEP_MAX = 110.0;
    const SEP_MIN = 8.0;

    // Shark grows and the swimmer doesn't - the threat scales, you don't.
    const SHARK_SIZE = [28.0, 34.0, 42.0];
    const SWIMMER_SIZE = 26.0;
    const SHARK_DEPTH = [46.0, 30.0, 14.0];

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as SwimController, phase as Float) as Void {
        var model = controller.model();
        if (model == null) {
            return;
        }
        var surface = waterlineY(metrics);

        if (!model.hunting) {
            Backdrop.draw(dc, metrics, surface, SwimConstants.DANGER_STAGE_CRUISE, phase);
            drawCirclingFin(dc, metrics, surface, phase);
            Figures.drawSwimmer(dc, metrics.centerX + metrics.px(58), surface + metrics.px(4), metrics.px(32),
                SwimConstants.DANGER_STAGE_CRUISE, phase);
            drawTopLine(dc, metrics, Utils.formatClock(model.elapsed), Palette.PALE);
            // Below the countdown rather than in the sky, which the fin's tip
            // reaches into; the teeth are still short here, so there's room.
            dc.setColor(Palette.ICE, Graphics.COLOR_TRANSPARENT);
            Hud.drawFitCenteredText(dc, metrics, readoutBottom(metrics) + metrics.px(8), 0,
                statLine(controller, model), (metrics.width * 0.56).toNumber());
            drawScentReadouts(dc, metrics, controller, model);
            Jaws.drawFrame(dc, metrics, 0.08 + 0.2 * model.scentProgress(), 1, phase);
            return;
        }

        var stage = model.stage();
        var danger = model.danger();
        Backdrop.draw(dc, metrics, surface, stage, phase);
        drawScene(dc, metrics, model, stage, phase);

        var jaws = (stage == SwimConstants.DANGER_STAGE_JAWS);
        if (jaws && (((phase / 0.6).toNumber()) % 2) == 0) {
            drawTopLine(dc, metrics, WatchUi.loadResource(Rez.Strings.SwimShout) as String, Palette.BONE);
        } else if (!jaws) {
            drawTopLine(dc, metrics, Utils.formatClock(model.elapsed), Palette.PALE);
        }
        drawStatRow(dc, metrics, statLine(controller, model), accentFor(stage));
        drawHuntReadouts(dc, metrics, controller, model, stage);

        var bite = 0.15 + 0.85 * danger;
        if (jaws) {
            bite += 0.07 * Math.sin(phase * 2.6);
        }
        var blood = 2;
        if (jaws) {
            blood = 7;
        } else if (stage == SwimConstants.DANGER_STAGE_CLOSING) {
            blood = 4;
        }
        Jaws.drawFrame(dc, metrics, bite, blood, phase);
    }

    function waterlineY(metrics as ScreenMetrics) as Number {
        return metrics.isRound ? metrics.px(150) : (metrics.height * 0.34).toNumber();
    }

    // --- scent phase ----------------------------------------------------------

    // Just a fin, big and close, sweeping back and forth on the left while
    // the shark circles - the threat you can see before it is released.
    function drawCirclingFin(dc as Graphics.Dc, metrics as ScreenMetrics, surface as Number, phase as Float) as Void {
        var s = metrics.px(46);
        if (s < 8) {
            s = 8;
        }
        var t = phase * 0.12;
        var x = metrics.centerX - metrics.px(92) + (Math.sin(t) * metrics.px(28)).toNumber();
        var dir = (Math.cos(t) >= 0.0) ? 1 : -1;
        Figures.drawFin(dc, x, surface + metrics.px(3), s, dir, phase);
    }

    function drawScentReadouts(dc as Graphics.Dc, metrics as ScreenMetrics, controller as SwimController, model as SwimModel) as Void {
        var rowY = readoutBottom(metrics);

        var label = WatchUi.loadResource(Rez.Strings.SharkIn) as String;
        var labelFont = metrics.fontFor(0);
        var labelH = dc.getFontHeight(labelFont);
        var top = waterlineY(metrics) + metrics.px(40);
        var available = rowY - top - labelH - metrics.px(4);
        if (available < metrics.px(26)) {
            available = metrics.px(26);
        }
        var numText = Utils.formatClock(model.scentSecondsLeft().toFloat());
        var font = Hud.fitHeroFont(dc, metrics, numText,
            (metrics.width * 0.42).toNumber(), available);
        var numY = rowY - metrics.px(4) - dc.getFontHeight(font);
        if (numY < top + labelH) {
            numY = top + labelH;
        }
        Hud.drawShadowText(dc, metrics.centerX, numY, font, numText, Palette.BONE, Palette.BLACK);
        dc.setColor(Palette.BLOOD_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, numY - labelH + metrics.px(6), labelFont, label, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // --- hunt -----------------------------------------------------------------

    function drawScene(dc as Graphics.Dc, metrics as ScreenMetrics, model as SwimModel, stage as Number, phase as Float) as Void {
        var gapFrac = model.gap() / model.headStartMeters;
        if (gapFrac > 1.0) {
            gapFrac = 1.0;
        } else if (gapFrac < 0.0) {
            gapFrac = 0.0;
        }

        var sharkSize = metrics.px(SHARK_SIZE[stage]);
        var swimmerSize = metrics.px(SWIMMER_SIZE);
        if (sharkSize < 5) {
            sharkSize = 5;
        }
        if (swimmerSize < 4) {
            swimmerSize = 4;
        }

        // Half-widths of what each figure occupies, tail and splash
        // included, so the pair stays centred as the shark grows.
        var sharkHalf = (sharkSize * 2.2).toNumber();
        var swimmerHalf = (swimmerSize * 1.5).toNumber();
        var sep = metrics.px(SEP_MIN + (SEP_MAX - SEP_MIN) * gapFrac);

        var totalW = sharkHalf * 2 + sep + swimmerHalf * 2;
        var sharkX = metrics.centerX - totalW / 2 + sharkHalf;
        var swimmerX = sharkX + sharkHalf + sep + swimmerHalf;

        var surface = waterlineY(metrics);
        Figures.drawShark(dc, sharkX, surface + metrics.px(SHARK_DEPTH[stage]), sharkSize, stage, phase);
        Figures.drawSwimmer(dc, swimmerX, surface, swimmerSize, stage, phase);
    }

    function drawHuntReadouts(dc as Graphics.Dc, metrics as ScreenMetrics, controller as SwimController, model as SwimModel, stage as Number) as Void {
        var rowY = readoutBottom(metrics);
        var tint = accentFor(stage);

        var numText = model.gap().format("%.0f");
        var unitText = WatchUi.loadResource(Rez.Strings.UnitMeters) as String;
        var unitFont = metrics.fontFor(1);
        // Below the shark's lowest fin at its deepest.
        var top = waterlineY(metrics) + metrics.px(78);
        var available = rowY - top - metrics.px(4);
        if (available < metrics.px(26)) {
            available = metrics.px(26);
        }
        var maxWidth = (metrics.width * 0.42).toNumber() - dc.getTextWidthInPixels(unitText, unitFont);
        var font = Hud.fitHeroFont(dc, metrics, numText, maxWidth, available);
        var y = rowY - metrics.px(4) - dc.getFontHeight(font);
        if (y < top) {
            y = top;
        }
        Hud.drawNumberWithUnit(dc, metrics.centerX, y, numText, unitText, font, unitFont, Palette.BONE, tint);
    }

    // --- shared -----------------------------------------------------------------

    // Clear of the lower fangs at their longest.
    function readoutBottom(metrics as ScreenMetrics) as Number {
        return metrics.height - (metrics.isRound ? metrics.px(96) : metrics.px(70));
    }

    // Distance and live pace. Separators are plain spacing: a middot can draw
    // as a tofu box on a device whose font lacks it.
    function statLine(controller as SwimController, model as SwimModel) as String {
        return Utils.formatDistance(model.swimmerMeters) + "   " + controller.currentPaceString()
            + (WatchUi.loadResource(Rez.Strings.UnitPer100) as String);
    }

    // Small line in the sky strip at the top: the clock, or SWIM! in the
    // last stage, blinking so it keeps catching the eye on every breath.
    function drawTopLine(dc as Graphics.Dc, metrics as ScreenMetrics, text as String, color as Number) as Void {
        var y = metrics.isRound ? metrics.px(74) : metrics.px(48);
        var font = metrics.fontFor(2);
        if (dc.getTextWidthInPixels(text, font) > metrics.px(150)) {
            font = metrics.fontFor(1);
        }
        Hud.drawShadowText(dc, metrics.centerX, y, font, text, color, Palette.BLACK);
    }

    // Distance and pace, in the sky strip under the clock.
    function drawStatRow(dc as Graphics.Dc, metrics as ScreenMetrics, text as String, color as Number) as Void {
        var y = metrics.isRound ? metrics.px(112) : metrics.px(86);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, y, 0, text, (metrics.width * 0.48).toNumber());
    }

    function accentFor(stage as Number) as Number {
        if (stage == SwimConstants.DANGER_STAGE_JAWS) {
            return Palette.BONE;
        } else if (stage == SwimConstants.DANGER_STAGE_CLOSING) {
            return Palette.AMBER;
        }
        return Palette.ICE;
    }
}
