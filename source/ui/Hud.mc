import Toybox.Graphics;
import Toybox.Lang;

// Shared text and chrome helpers, so no screen reimplements a centred-text
// loop or its own pixel maths.
//
// Nearly everything here is about *measuring before drawing*. Garmin's fonts
// are a fixed enum whose members are wildly different sizes across the device
// range, so a string that fits a 416 px Venu comfortably will run off the
// side of a 176 px Instinct at the same tier. Every hero number and headline
// in this app is fitted at draw time rather than assumed.
module Hud {

    function drawCenteredText(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, tier as Number, text as String) as Void {
        dc.drawText(metrics.centerX, y, metrics.fontFor(tier), text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Steps the font tier down until the string fits maxWidth.
    function drawFitCenteredText(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, tier as Number, text as String, maxWidth as Number) as Void {
        var t = tier;
        while (t > 0 && dc.getTextWidthInPixels(text, metrics.fontFor(t)) > maxWidth) {
            t -= 1;
        }
        dc.drawText(metrics.centerX, y, metrics.fontFor(t), text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Greedy word-wrap - Dc.drawText has none of its own. Returns the y just
    // below the last line drawn.
    function drawWrappedCenteredText(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, tier as Number, text as String, maxWidth as Number) as Number {
        var font = metrics.fontFor(tier);
        var lineH = dc.getFontHeight(font);
        var lines = wrapLines(dc, font, text, maxWidth);
        var cursor = y;
        for (var i = 0; i < lines.size(); i += 1) {
            dc.drawText(metrics.centerX, cursor, font, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
            cursor += lineH;
        }
        return cursor;
    }

    // Wrapped copy that has to fit a vertical band as well as a width:
    // guarding only line width isn't enough for the instruction cards, where
    // a paragraph that wraps to one extra line runs off the bottom even
    // though every individual line is narrow enough.
    function drawFitWrappedCenteredText(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, tier as Number, text as String, maxWidth as Number, maxBottom as Number) as Number {
        var t = tier;
        while (t > 0 && wrappedHeight(dc, metrics, t, text, maxWidth) > maxBottom - y) {
            t -= 1;
        }
        return drawWrappedCenteredText(dc, metrics, y, t, text, maxWidth);
    }

    function wrappedHeight(dc as Graphics.Dc, metrics as ScreenMetrics, tier as Number, text as String, maxWidth as Number) as Number {
        var font = metrics.fontFor(tier);
        return wrapLines(dc, font, text, maxWidth).size() * dc.getFontHeight(font);
    }

    function wrapLines(dc as Graphics.Dc, font as Graphics.FontType, text as String, maxWidth as Number) as Array<String> {
        var lines = [] as Array<String>;
        var words = splitWords(text);
        var line = "";
        for (var i = 0; i < words.size(); i += 1) {
            var candidate = (line.length() == 0) ? (words[i] as String) : (line + " " + words[i]);
            if (line.length() > 0 && dc.getTextWidthInPixels(candidate, font) > maxWidth) {
                lines.add(line);
                line = words[i] as String;
            } else {
                line = candidate;
            }
        }
        if (line.length() > 0) {
            lines.add(line);
        }
        return lines;
    }

    function splitWords(text as String) as Array<String> {
        var words = [] as Array<String>;
        var rest = text;
        var idx = rest.find(" ");
        while (idx != null) {
            if (idx > 0) {
                words.add(rest.substring(0, idx) as String);
            }
            rest = rest.substring(idx + 1, rest.length()) as String;
            idx = rest.find(" ");
        }
        if (rest.length() > 0) {
            words.add(rest);
        }
        return words;
    }

    // Largest of Garmin's number fonts that fits the given box, stepping
    // down the fixed enum.
    function fitNumberFont(dc as Graphics.Dc, startFont as Graphics.FontType, text as String, maxWidth as Number, maxHeight as Number) as Graphics.FontType {
        var font = startFont;
        while ((dc.getFontHeight(font) > maxHeight || dc.getTextWidthInPixels(text, font) > maxWidth)
                && font != smallerNumberFont(font)) {
            font = smallerNumberFont(font);
        }
        return font;
    }

    // Hero font for a number or clock: the largest number font that fits,
    // and if even the smallest one is too tall (the 208 px screens), the
    // largest text font that does.
    function fitHeroFont(dc as Graphics.Dc, metrics as ScreenMetrics, text as String, maxWidth as Number, maxHeight as Number) as Graphics.FontType {
        var font = fitNumberFont(dc, biggestNumberFont(metrics), text, maxWidth, maxHeight);
        if (dc.getFontHeight(font) <= maxHeight) {
            return font;
        }
        var tier = 4;
        while (tier > 0 && (dc.getFontHeight(metrics.fontFor(tier)) > maxHeight
                || dc.getTextWidthInPixels(text, metrics.fontFor(tier)) > maxWidth)) {
            tier -= 1;
        }
        return metrics.fontFor(tier);
    }

    function smallerNumberFont(font as Graphics.FontType) as Graphics.FontType {
        if (font == Graphics.FONT_NUMBER_THAI_HOT) {
            return Graphics.FONT_NUMBER_HOT;
        } else if (font == Graphics.FONT_NUMBER_HOT) {
            return Graphics.FONT_NUMBER_MEDIUM;
        } else if (font == Graphics.FONT_NUMBER_MEDIUM) {
            return Graphics.FONT_NUMBER_MILD;
        }
        return font;
    }

    function biggestNumberFont(metrics as ScreenMetrics) as Graphics.FontType {
        if (metrics.scale >= 0.85) {
            return Graphics.FONT_NUMBER_THAI_HOT;
        } else if (metrics.scale >= 0.55) {
            return Graphics.FONT_NUMBER_HOT;
        }
        return Graphics.FONT_NUMBER_MEDIUM;
    }

    // A hero number with a small unit sitting on its baseline. Baselines are
    // aligned by glyph rather than by font cell, since Garmin's big number
    // fonts carry a lot of descent padding and cell-bottom alignment leaves
    // the unit floating well below the digits.
    //
    // Takes an explicit centre x rather than a ScreenMetrics, because the
    // low-end devices in the target list cap methods at nine arguments and
    // this is the widest signature in the project - it was over by exactly
    // the one parameter it never read.
    function drawNumberWithUnit(dc as Graphics.Dc, centerXPos as Number, topY as Number, numText as String, unitText as String, numFont as Graphics.FontType, unitFont as Graphics.FontType, numColor as Graphics.ColorType, unitColor as Graphics.ColorType) as Void {
        var numW = dc.getTextWidthInPixels(numText, numFont);
        var numH = dc.getFontHeight(numFont);
        var unitW = dc.getTextWidthInPixels(unitText, unitFont);
        var unitH = dc.getFontHeight(unitFont);

        var startX = centerXPos - (numW + unitW) / 2;
        dc.setColor(numColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, topY, numFont, numText, Graphics.TEXT_JUSTIFY_LEFT);

        var unitY = topY + (numH - Graphics.getFontDescent(numFont)) - (unitH - Graphics.getFontDescent(unitFont));
        dc.setColor(unitColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + numW, unitY, unitFont, unitText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // The left-edge UP/DOWN chevron pair that marks button navigation on
    // every screen that has a selection. Buttons are the baseline across the
    // device range - touch is a bonus on a minority of them, and useless to
    // a wet hand anyway.
    function drawNavChevrons(dc as Graphics.Dc, metrics as ScreenMetrics, color as Graphics.ColorType, spreadBaseline as Number) as Void {
        // Inboard of the fangs at 9 o'clock.
        var x = metrics.px(68);
        var w = metrics.px(8);
        if (w < 3) {
            w = 3;
        }
        var spread = metrics.px(spreadBaseline);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        var upY = metrics.centerY - spread;
        dc.fillPolygon([
            [x - w, upY + w],
            [x, upY - w],
            [x + w, upY + w]
        ]);

        var downY = metrics.centerY + spread;
        dc.fillPolygon([
            [x - w, downY - w],
            [x, downY + w],
            [x + w, downY - w]
        ]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // A single menu pill: blood-filled with bone text when selected, an
    // outline otherwise. Selection is also carried by size, so it survives
    // the 64-colour MIP panels.
    function drawPill(dc as Graphics.Dc, metrics as ScreenMetrics, topY as Number, label as String, selected as Boolean, widthBaseline as Number) as Number {
        var h = selected ? metrics.px(54) : metrics.px(42);
        var w = metrics.px(selected ? widthBaseline + 16 : widthBaseline);
        var x = metrics.centerX - w / 2;
        var r = h / 2;
        if (selected) {
            dc.setColor(Palette.BLOOD_DARK, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, topY + metrics.px(4), w, h, r);
            dc.setColor(Palette.CHIP_FILL, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, topY, w, h, r);
            dc.setColor(Palette.CHIP_LABEL, Graphics.COLOR_TRANSPARENT);
        } else {
            var pen = metrics.px(3);
            dc.setPenWidth(pen > 0 ? pen : 1);
            dc.setColor(Palette.PANEL, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(x, topY, w, h, r);
            dc.setPenWidth(1);
            dc.setColor(Palette.PALE, Graphics.COLOR_TRANSPARENT);
        }
        var tier = selected ? 3 : 1;
        while (tier > 0 && dc.getTextWidthInPixels(label, metrics.fontFor(tier)) > w - metrics.px(20)) {
            tier -= 1;
        }
        dc.drawText(metrics.centerX, topY + h / 2, metrics.fontFor(tier), label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        return topY + h;
    }

    // Text with a hard drop shadow, for headlines that sit over busy water.
    function drawShadowText(dc as Graphics.Dc, x as Number, y as Number, font as Graphics.FontType, text as String, color as Number, shadow as Number) as Void {
        var off = (dc.getFontHeight(font) / 22);
        if (off < 1) {
            off = 1;
        }
        dc.setColor(shadow, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + off, y + off, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
