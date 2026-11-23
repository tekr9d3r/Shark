import Toybox.Graphics;
import Toybox.Math;
import Toybox.WatchUi;
import Toybox.Lang;

// Opens inside the jaws: bloody fangs on the rim, the wordmark in bone, a
// shark prowling the dark water, and one big pill - START is pre-selected
// so a swimmer at the water's edge opens the app and presses once.
//
// The menu is a carousel (one pill plus position dots) rather than a stack:
// three stacked pills don't fit between the fangs on a round screen.
module HomeScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as SwimController, phase as Float) as Void {
        var h = metrics.height;
        var surface = (h * 0.47).toNumber();
        Backdrop.draw(dc, metrics, surface, SwimConstants.DANGER_STAGE_CRUISE, phase);

        drawProwler(dc, metrics, surface, phase);
        drawGps(dc, metrics, controller, (h * 0.17).toNumber());
        drawWordmark(dc, metrics, (h * 0.21).toNumber());

        var labels = [
            WatchUi.loadResource(Rez.Strings.HomeStart) as String,
            WatchUi.loadResource(Rez.Strings.HomeHowTo) as String,
            WatchUi.loadResource(Rez.Strings.HomeExit) as String
        ];
        var index = controller.homeIndex();
        var pillTop = (h * 0.63).toNumber();
        var bottom = Hud.drawPill(dc, metrics, pillTop, labels[index], true, 176);
        drawDots(dc, metrics, bottom + metrics.px(18), index);
        Hud.drawNavChevrons(dc, metrics, Palette.BONE_DIM, 30);

        Jaws.drawFrame(dc, metrics, 0.55, 4, phase);
    }

    // A shark patrolling just under the surface, back and forth across the
    // middle of the screen with only its back and fin breaking the water.
    function drawProwler(dc as Graphics.Dc, metrics as ScreenMetrics, surface as Number, phase as Float) as Void {
        var size = metrics.px(24);
        if (size < 6) {
            size = 6;
        }
        var drift = (Math.sin(phase * 0.08) * metrics.px(70)).toNumber();
        Figures.drawShark(dc, metrics.centerX + drift, surface + metrics.px(30), size,
            SwimConstants.DANGER_STAGE_CRUISE, phase * 0.6);
    }

    // SHARK in bone over a hard blood shadow.
    function drawWordmark(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number) as Void {
        var text = WatchUi.loadResource(Rez.Strings.HomeTitle) as String;
        var font = metrics.fontFor(4);
        var maxW = metrics.width - metrics.px(150);
        var tier = 4;
        while (tier > 1 && dc.getTextWidthInPixels(text, font) > maxW) {
            tier -= 1;
            font = metrics.fontFor(tier);
        }
        var fontH = dc.getFontHeight(font);

        Hud.drawShadowText(dc, metrics.centerX, y, font, text, Palette.BONE, Palette.BLOOD_DARK);

        // The full line where it fits, the short one on narrow screens.
        var subW = metrics.isRound ? metrics.width - metrics.px(170) : (metrics.width * 0.74).toNumber();
        var sub = WatchUi.loadResource(Rez.Strings.HomeSubtitle) as String;
        if (dc.getTextWidthInPixels(sub, metrics.fontFor(0)) > subW) {
            sub = WatchUi.loadResource(Rez.Strings.HomeSubtitleShort) as String;
        }
        dc.setColor(Palette.ICE, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, y + fontH + metrics.px(10), 0, sub, subW);
    }

    // GPS status as a dot and a word, coloured by fix quality, so the
    // swimmer can watch the fix land before wading in. Never blocks START.
    function drawGps(dc as Graphics.Dc, metrics as ScreenMetrics, controller as SwimController, y as Number) as Void {
        var tier = SwimConstants.gpsTier(controller.gpsAccuracy());
        var color = Palette.BLOOD_BRIGHT;
        if (tier == SwimConstants.GPS_TIER_READY) {
            color = Palette.TEAL;
        } else if (tier == SwimConstants.GPS_TIER_WEAK) {
            color = Palette.AMBER;
        }
        var font = metrics.fontFor(0);
        var label = WatchUi.loadResource(Rez.Strings.Gps) as String;
        var r = metrics.px(5);
        if (r < 2) {
            r = 2;
        }
        var textW = dc.getTextWidthInPixels(label, font);
        var gap = metrics.px(8);
        var startX = metrics.centerX - (r * 2 + gap + textW) / 2;
        var fh = dc.getFontHeight(font);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(startX + r, y - fh / 2, r);
        dc.drawText(startX + r * 2 + gap, y - fh, font, label, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawDots(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, index as Number) as Void {
        var r = metrics.px(4);
        if (r < 2) {
            r = 2;
        }
        var gap = metrics.px(16);
        var count = SwimConstants.HOME_OPTION_COUNT;
        var startX = metrics.centerX - ((count - 1) * gap) / 2;
        for (var i = 0; i < count; i += 1) {
            dc.setColor((i == index) ? Palette.BONE : Palette.PANEL, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(startX + i * gap, y, r);
        }
    }
}
