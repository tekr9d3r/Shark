import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// End of the swim. The recording has already been saved by the time this
// draws, which is why it is allowed to animate.
//
//   EATEN   the shark closed the gap - the normal end of a warm-up. Blood
//           water, fangs fully closed and dripping, the shark with its jaws
//           open, and how long you lasted as the hero.
//   STOPPED ended by hand from the menu, swim kept.
//
// Under the hero: distance and average pace, because those are what the
// swim was worth however the game went.
module ResultScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as SwimController, phase as Float) as Void {
        var eaten = (controller.endReason() == SwimConstants.REASON_EATEN);
        var stage = eaten ? SwimConstants.DANGER_STAGE_JAWS : SwimConstants.DANGER_STAGE_CRUISE;
        var surface = metrics.isRound ? metrics.px(128) : (metrics.height * 0.3).toNumber();

        Backdrop.draw(dc, metrics, surface, stage, phase);
        drawHeadline(dc, metrics, layout, eaten);

        var size = metrics.px(eaten ? 24 : 20);
        if (size < 5) {
            size = 5;
        }
        Figures.drawShark(dc, metrics.centerX - metrics.px(8), surface + metrics.px(eaten ? 22 : 34), size, stage, phase * 0.7);

        drawStats(dc, metrics, controller, surface + metrics.px(58));

        dc.setColor(Palette.MUTED, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.hintY, 0,
            WatchUi.loadResource(Rez.Strings.HintHome) as String,
            (metrics.width * 0.5).toNumber());

        Jaws.drawFrame(dc, metrics, eaten ? 1.0 : 0.3, eaten ? 9 : 3, phase);
    }

    function drawHeadline(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, eaten as Boolean) as Void {
        var text = WatchUi.loadResource(eaten ? Rez.Strings.ResultEaten : Rez.Strings.ResultStopped) as String;
        var tier = 3;
        var maxW = (metrics.width * 0.56).toNumber();
        while (tier > 0 && dc.getTextWidthInPixels(text, metrics.fontFor(tier)) > maxW) {
            tier -= 1;
        }
        var y = metrics.isRound ? metrics.px(74) : layout.titleY;
        Hud.drawShadowText(dc, metrics.centerX, y, metrics.fontFor(tier), text,
            Palette.BONE, eaten ? Palette.BLACK : Palette.BLOOD_DARK);
    }

    // Hero: how long you lasted once the shark was in the water. A swim
    // ended inside the scent window has no hunt to score, so it shows the
    // total time instead.
    function drawStats(dc as Graphics.Dc, metrics as ScreenMetrics, controller as SwimController, top as Number) as Void {
        var hunt = controller.finalHuntSeconds();
        var labelId = (hunt > 0.0) ? Rez.Strings.Survived : Rez.Strings.TotalTime;
        var heroText = Utils.formatClock((hunt > 0.0) ? hunt : controller.finalSeconds());
        var rowText = Utils.formatDistance(controller.finalMeters()) + "   "
            + controller.averagePaceString()
            + (WatchUi.loadResource(Rez.Strings.UnitPer100) as String);

        var labelFont = metrics.fontFor(0);
        var labelH = dc.getFontHeight(labelFont);
        var rowFont = metrics.fontFor(0);
        var rowH = dc.getFontHeight(rowFont);
        var bottom = metrics.height - (metrics.isRound ? metrics.px(98) : metrics.px(84));
        var rowY = bottom - rowH;

        var available = rowY - top - labelH - metrics.px(4);
        if (available < metrics.px(24)) {
            available = metrics.px(24);
        }
        var font = Hud.fitHeroFont(dc, metrics, heroText,
            (metrics.width * 0.5).toNumber(), available);
        var heroY = rowY - metrics.px(2) - dc.getFontHeight(font);
        if (heroY < top + labelH) {
            heroY = top + labelH;
        }

        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, heroY - labelH + metrics.px(6), labelFont,
            WatchUi.loadResource(labelId) as String, Graphics.TEXT_JUSTIFY_CENTER);
        Hud.drawShadowText(dc, metrics.centerX, heroY, font, heroText, Palette.BONE, Palette.BLACK);

        dc.setColor(Palette.PALE, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, rowY, 0, rowText, (metrics.width * 0.56).toNumber());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
}
