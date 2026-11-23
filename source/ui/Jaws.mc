import Toybox.Graphics;
import Toybox.Math;
import Toybox.Lang;

// The frame every screen sits in: you are inside the shark's mouth. A ring of
// gum at the bezel and a row of fangs pointing inward, some tipped with
// blood that slowly drips toward the middle of the screen.
//
// `bite` (0..1) is how far the jaws have closed - it scales the fangs from
// stubs to long enough to crowd the readouts. On the swim screen it is the
// danger meter itself: the closer the shark, the longer the teeth, so the
// frame answers "how close is it" in peripheral vision.
//
// `blood` (0..10) is how many teeth in every ten carry blood.
//
// Drawn from polygons and lines only, so it scales from a 208 px Forerunner
// to a 454 px Venu with no assets. Round screens get a ring of radial teeth;
// rectangular ones get a row along each edge.
module Jaws {

    // How many of every ten teeth are bloody, and the animation phase for
    // the drips. Module state rather than parameters because drawTooth is
    // already at the nine-argument limit of the low-end devices.
    var bloodLevel as Number = 0;
    var dripPhase as Float = 0.0;

    function drawFrame(dc as Graphics.Dc, metrics as ScreenMetrics, bite as Float, blood as Number, phase as Float) as Void {
        bloodLevel = blood;
        dripPhase = phase;
        var b = bite;
        if (b < 0.0) {
            b = 0.0;
        } else if (b > 1.0) {
            b = 1.0;
        }

        var gum = metrics.px(13);
        if (gum < 4) {
            gum = 4;
        }

        if (metrics.isRound) {
            drawRound(dc, metrics, b, gum);
        } else {
            drawRect(dc, metrics, b, gum);
        }
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Longest fang, in baseline pixels, for a given bite. Callers use the
    // same number to keep readouts clear of the teeth.
    function toothLength(metrics as ScreenMetrics, bite as Float) as Number {
        return metrics.px(14.0 + 38.0 * bite);
    }

    function drawRound(dc as Graphics.Dc, metrics as ScreenMetrics, bite as Float, gum as Number) as Void {
        var r = metrics.minDim / 2;
        var cx = metrics.centerX;
        var cy = metrics.centerY;

        // Gum: a dark band with a lighter inner lip for depth.
        dc.setColor(Palette.GUM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(gum);
        dc.drawCircle(cx, cy, r - gum / 2);
        var lip = metrics.px(3);
        if (lip < 1) {
            lip = 1;
        }
        dc.setColor(Palette.GUM_LIGHT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(lip);
        dc.drawCircle(cx, cy, r - gum + lip / 2);
        dc.setPenWidth(1);

        var count = (metrics.minDim >= 300) ? 26 : 20;
        var baseR = (r - gum + lip).toFloat();
        var step = Math.PI * 2.0 / count;
        var halfW = (baseR * Math.sin(step / 2.0) * 0.98).toNumber();
        var full = toothLength(metrics, bite);

        // Half a step of rotation so the gap, not a fang, sits at 12 o'clock -
        // that is where the activity's top text goes.
        for (var i = 0; i < count; i += 1) {
            var a = step * i + step / 2.0;
            var ux = -Math.sin(a);
            var uy = Math.cos(a);
            var bx = cx - (ux * baseR).toNumber();
            var by = cy - (uy * baseR).toNumber();
            var len = (i % 2 == 0) ? full : (full * 0.7).toNumber();
            drawTooth(dc, bx, by, ux, uy, halfW, len, i, metrics.scale);
        }
    }

    function drawRect(dc as Graphics.Dc, metrics as ScreenMetrics, bite as Float, gum as Number) as Void {
        var w = metrics.width;
        var h = metrics.height;

        dc.setColor(Palette.GUM, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, w, gum);
        dc.fillRectangle(0, h - gum, w, gum);
        dc.fillRectangle(0, 0, gum, h);
        dc.fillRectangle(w - gum, 0, gum, h);

        var full = toothLength(metrics, bite);
        var pitch = metrics.px(34);
        if (pitch < 10) {
            pitch = 10;
        }
        var halfW = pitch / 2;

        var idx = 0;
        var n = (w - 2 * gum) / pitch;
        var x0 = (w - n * pitch) / 2 + halfW;
        for (var i = 0; i < n; i += 1) {
            var len = (i % 2 == 0) ? full : (full * 0.7).toNumber();
            drawTooth(dc, x0 + i * pitch, gum - 1, 0.0, 1.0, halfW, len, idx, metrics.scale);
            idx += 1;
            drawTooth(dc, x0 + i * pitch, h - gum + 1, 0.0, -1.0, halfW, len, idx, metrics.scale);
            idx += 1;
        }

        // Side rows stop short of the corners, where top and bottom teeth
        // already crowd.
        var m = (h - 2 * gum - 2 * full) / pitch;
        var y0 = (h - m * pitch) / 2 + halfW;
        for (var j = 0; j < m; j += 1) {
            var len2 = (j % 2 == 0) ? (full * 0.8).toNumber() : (full * 0.6).toNumber();
            drawTooth(dc, gum - 1, y0 + j * pitch, 1.0, 0.0, halfW, len2, idx, metrics.scale);
            idx += 1;
            drawTooth(dc, w - gum + 1, y0 + j * pitch, -1.0, 0.0, halfW, len2, idx, metrics.scale);
            idx += 1;
        }
    }

    // One fang: a tapered five-point blade from the gum toward (ux, uy), lit
    // on one side and shaded on the other, optionally bloody at the tip and
    // dripping.
    function drawTooth(dc as Graphics.Dc, bx as Number, by as Number, ux as Float, uy as Float, halfW as Number, len as Number, idx as Number, scale as Float) as Void {
        if (len < 3) {
            return;
        }
        var px = -uy;
        var py = ux;
        var hw = halfW.toFloat();
        var l = len.toFloat();

        var blX = bx + (px * hw).toNumber();
        var blY = by + (py * hw).toNumber();
        var brX = bx - (px * hw).toNumber();
        var brY = by - (py * hw).toNumber();
        var mlX = bx + (ux * l * 0.5 + px * hw * 0.55).toNumber();
        var mlY = by + (uy * l * 0.5 + py * hw * 0.55).toNumber();
        var mrX = bx + (ux * l * 0.5 - px * hw * 0.55).toNumber();
        var mrY = by + (uy * l * 0.5 - py * hw * 0.55).toNumber();
        var tipX = bx + (ux * l).toNumber();
        var tipY = by + (uy * l).toNumber();

        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[blX, blY], [mlX, mlY], [tipX, tipY], [mrX, mrY], [brX, brY]]);

        // Shaded half, from the blade's spine to its right edge.
        dc.setColor(Palette.BONE_SHADE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[bx, by], [tipX, tipY], [mrX, mrY], [brX, brY]]);

        var hash = (idx * 7 + 3) % 10;
        if (hash >= bloodLevel) {
            return;
        }

        // Blood over the last ~40% of the blade.
        var tlX = bx + (ux * l * 0.6 + px * hw * 0.42).toNumber();
        var tlY = by + (uy * l * 0.6 + py * hw * 0.42).toNumber();
        var trX = bx + (ux * l * 0.6 - px * hw * 0.42).toNumber();
        var trY = by + (uy * l * 0.6 - py * hw * 0.42).toNumber();
        dc.setColor(Palette.BLOOD, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[tlX, tlY], [tipX, tipY], [trX, trY]]);

        // Every other bloody tooth drips: a thread that stretches from the
        // tip and lets a drop go, on its own slow cycle.
        if (hash % 2 != 0) {
            return;
        }
        var cycle = dripPhase * 0.09 + idx * 0.37;
        var f = cycle - cycle.toNumber();
        var reach = (6.0 + 22.0 * f) * scale;
        var pen = (3.0 * scale).toNumber();
        dc.setPenWidth(pen > 0 ? pen : 1);
        var endX = tipX + (ux * reach).toNumber();
        var endY = tipY + (uy * reach).toNumber();
        dc.drawLine(tipX, tipY, endX, endY);
        var dropR = ((2.5 + 2.0 * f) * scale).toNumber();
        dc.fillCircle(endX, endY, dropR > 1 ? dropR : 1);
        dc.setPenWidth(1);
    }
}
