import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Three cards, paged with UP/DOWN and advanced with SELECT, answering the
// three questions in the order they come up: what happens when I press
// START, how do I stay alive, and what do the buzzes mean once my face is in
// the water.
module InstructionsScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as SwimController, phase as Float) as Void {
        var bands = Palette.WATER_CRUISE;
        dc.setColor(bands[3] as Number, bands[3] as Number);
        dc.fillRectangle(0, 0, metrics.width, metrics.height);

        var page = controller.instructionsPage();
        drawTitle(dc, metrics, layout, titleFor(page));
        drawBody(dc, metrics, layout, page);
        drawPageDots(dc, metrics, layout, page);
        drawHint(dc, metrics, layout, page);

        Jaws.drawFrame(dc, metrics, 0.2, 3, phase);
    }

    function titleFor(page as Number) as String {
        var id = Rez.Strings.InstrTitleStart;
        if (page == 1) {
            id = Rez.Strings.InstrTitlePace;
        } else if (page == 2) {
            id = Rez.Strings.InstrTitleFeel;
        }
        return WatchUi.loadResource(id) as String;
    }

    function drawTitle(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, title as String) as Void {
        var font = metrics.fontFor(2);
        var maxW = (metrics.width * 0.6).toNumber();
        var tier = 2;
        while (tier > 0 && dc.getTextWidthInPixels(title, font) > maxW) {
            tier -= 1;
            font = metrics.fontFor(tier);
        }
        Hud.drawShadowText(dc, metrics.centerX, layout.titleY, font, title, Palette.BLOOD_BRIGHT, Palette.BLACK);
    }

    // The last card is a legend rather than a paragraph: three marks against
    // three buzz meanings, which is the shape the information actually has.
    function drawBody(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, page as Number) as Void {
        if (page == 2) {
            drawSignalLegend(dc, metrics, layout);
            return;
        }
        var id = (page == 0) ? Rez.Strings.InstrBodyStart : Rez.Strings.InstrBodyPace;
        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitWrappedCenteredText(dc, metrics, layout.stageTop, 2,
            WatchUi.loadResource(id) as String,
            (metrics.width * 0.68).toNumber(), layout.stageBottom);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function drawSignalLegend(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout) as Void {
        var rows = [
            WatchUi.loadResource(Rez.Strings.InstrSignalRelease) as String,
            WatchUi.loadResource(Rez.Strings.InstrSignalClosing) as String,
            WatchUi.loadResource(Rez.Strings.InstrSignalJaws) as String
        ];
        var colors = [Palette.ICE, Palette.AMBER, Palette.BLOOD_BRIGHT];

        var dotR = metrics.px(7);
        if (dotR < 2) {
            dotR = 2;
        }
        var textX = metrics.px(10) + dotR * 2;
        var maxW = (metrics.width * 0.66).toNumber() - textX;

        // One size for all three rows: step down until the widest fits.
        var tier = 1;
        var font = metrics.fontFor(tier);
        while (tier > 0 && widestRow(dc, rows, font) > maxW) {
            tier -= 1;
            font = metrics.fontFor(tier);
        }
        var lineH = dc.getFontHeight(font);
        var rowGap = metrics.px(10);
        var totalH = rows.size() * lineH + (rows.size() - 1) * rowGap;
        var y = layout.stageTop + ((layout.stageBottom - layout.stageTop) - totalH) / 2;

        // Centre the legend as a block.
        var widest = widestRow(dc, rows, font);
        if (widest > maxW) {
            widest = maxW;
        }
        var left = metrics.centerX - (textX + widest) / 2;

        for (var i = 0; i < rows.size(); i += 1) {
            dc.setColor(colors[i], Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(left + dotR, y + lineH / 2, dotR);
            dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left + textX, y, font, rows[i], Graphics.TEXT_JUSTIFY_LEFT);
            y += lineH + rowGap;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function widestRow(dc as Graphics.Dc, rows as Array<String>, font as Graphics.FontType) as Number {
        var widest = 0;
        for (var i = 0; i < rows.size(); i += 1) {
            var tw = dc.getTextWidthInPixels(rows[i], font);
            if (tw > widest) {
                widest = tw;
            }
        }
        return widest;
    }

    function drawPageDots(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, page as Number) as Void {
        var r = metrics.px(5);
        if (r < 2) {
            r = 2;
        }
        var gap = metrics.px(18);
        var count = SwimConstants.INSTRUCTIONS_PAGE_COUNT;
        var startX = metrics.centerX - ((count - 1) * gap) / 2;
        var y = layout.stageBottom + metrics.px(10);

        for (var i = 0; i < count; i += 1) {
            dc.setColor((i == page) ? Palette.BLOOD_BRIGHT : Palette.PANEL, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(startX + i * gap, y, r);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function drawHint(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, page as Number) as Void {
        var id = (page == SwimConstants.INSTRUCTIONS_PAGE_COUNT - 1)
            ? Rez.Strings.HintDone : Rez.Strings.HintNext;
        dc.setColor(Palette.MUTED, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.hintY, 0,
            WatchUi.loadResource(id) as String, (metrics.width * 0.5).toNumber());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
}
