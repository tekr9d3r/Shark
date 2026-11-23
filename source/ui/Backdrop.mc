import Toybox.Graphics;
import Toybox.Math;
import Toybox.Lang;

// The water every scene sits in: a dark sky strip, a rolling surface with a
// bright lip, four depth bands that get darker toward the bottom, faint
// light shafts in calm water and bubbles drifting up.
//
// The palette shifts per danger stage - cold teal, murky green, then blood -
// so the backdrop is itself a danger readout. All flat fills: the bands
// fake a gradient on AMOLED and collapse gracefully to fewer steps on the
// 64-colour MIP panels.
module Backdrop {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, surfaceY as Number, stage as Number, phase as Float) as Void {
        var w = metrics.width;
        var h = metrics.height;
        var bands = bandsFor(stage);
        var jaws = (stage == SwimConstants.DANGER_STAGE_JAWS);

        var sky = jaws ? Palette.SKY_JAWS : Palette.SKY;
        dc.setColor(sky, sky);
        dc.fillRectangle(0, 0, w, h);

        // Depth bands, the top one thinnest so the brightest water hugs the
        // surface.
        var amp = metrics.px(5);
        if (amp < 2) {
            amp = 2;
        }
        var top = surfaceY + amp;
        var depth = h - top;
        var fractions = [0.0, 0.16, 0.38, 0.64];
        for (var i = 0; i < 4; i += 1) {
            var y0 = top + (depth * (fractions[i] as Float)).toNumber();
            var c = bands[i] as Number;
            dc.setColor(c, c);
            dc.fillRectangle(0, y0, w, h - y0);
        }

        if (stage == SwimConstants.DANGER_STAGE_CRUISE) {
            drawShafts(dc, metrics, top, phase);
        }
        drawSurface(dc, metrics, surfaceY, amp, bands[0] as Number, surfaceFor(stage), phase);
        drawBubbles(dc, metrics, top, jaws ? Palette.BUBBLE_JAWS : Palette.BUBBLE, phase);
    }

    function bandsFor(stage as Number) as Array {
        if (stage == SwimConstants.DANGER_STAGE_JAWS) {
            return Palette.WATER_JAWS;
        } else if (stage == SwimConstants.DANGER_STAGE_CLOSING) {
            return Palette.WATER_CLOSING;
        }
        return Palette.WATER_CRUISE;
    }

    function surfaceFor(stage as Number) as Number {
        if (stage == SwimConstants.DANGER_STAGE_JAWS) {
            return Palette.SURFACE_JAWS;
        } else if (stage == SwimConstants.DANGER_STAGE_CLOSING) {
            return Palette.SURFACE_CLOSING;
        }
        return Palette.SURFACE_CRUISE;
    }

    // A rolling sine surface: the band-0 water filled up to the wave, then
    // the crest traced in the brighter lip colour.
    function drawSurface(dc as Graphics.Dc, metrics as ScreenMetrics, surfaceY as Number, amp as Number, water as Number, lip as Number, phase as Float) as Void {
        var w = metrics.width;
        var segs = 14;
        var pts = [] as Array<Graphics.Point2D>;
        for (var k = 0; k <= segs; k += 1) {
            var x = (w * k) / segs;
            var y = surfaceY + (Math.sin(k * 0.9 + phase * 0.8) * amp).toNumber();
            pts.add([x, y]);
        }
        var floor = surfaceY + amp + 2;
        var poly = [] as Array<Graphics.Point2D>;
        poly.addAll(pts);
        poly.add([w, floor]);
        poly.add([0, floor]);
        dc.setColor(water, water);
        dc.fillPolygon(poly);

        var pen = metrics.px(3);
        dc.setPenWidth(pen > 1 ? pen : 1);
        dc.setColor(lip, Graphics.COLOR_TRANSPARENT);
        for (var k = 0; k < segs; k += 1) {
            var a = pts[k];
            var b = pts[k + 1];
            dc.drawLine(a[0], a[1], b[0], b[1]);
        }
        dc.setPenWidth(1);
    }

    // Two slanted beams of a lighter blue, swaying very slowly.
    function drawShafts(dc as Graphics.Dc, metrics as ScreenMetrics, top as Number, phase as Float) as Void {
        var h = metrics.height;
        var sway = (Math.sin(phase * 0.15) * metrics.px(14)).toNumber();
        var slant = metrics.px(70);
        var bottom = top + ((h - top) * 0.55).toNumber();
        dc.setColor(Palette.SHAFT, Graphics.COLOR_TRANSPARENT);
        var starts = [0.30, 0.58];
        var widths = [22, 12];
        for (var i = 0; i < 2; i += 1) {
            var x = (metrics.width * (starts[i] as Float)).toNumber() + sway;
            var bw = metrics.px(widths[i] as Number);
            dc.fillPolygon([
                [x, top],
                [x + bw, top],
                [x + bw + slant, bottom],
                [x + slant - bw / 2, bottom]
            ]);
        }
    }

    // Six bubbles on staggered cycles, wobbling as they rise. Smaller than a
    // swimmer's cap so they never read as figures.
    function drawBubbles(dc as Graphics.Dc, metrics as ScreenMetrics, top as Number, color as Number, phase as Float) as Void {
        var h = metrics.height;
        var span = h - top - metrics.px(10);
        if (span < 10) {
            return;
        }
        var rise = metrics.px(7);
        if (rise < 1) {
            rise = 1;
        }
        var pen = metrics.px(2);
        dc.setPenWidth(pen > 1 ? pen : 1);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 6; i += 1) {
            var travel = ((phase * rise).toNumber() + i * (span / 6 + metrics.px(13))) % span;
            var y = h - metrics.px(10) - travel;
            var x = (metrics.width * (0.14 + 0.145 * i)).toNumber()
                + (Math.sin(phase * 0.7 + i * 1.3) * metrics.px(5)).toNumber();
            var r = metrics.px(3 + (i % 3) * 2);
            if (r < 1) {
                r = 1;
            }
            dc.drawCircle(x, y, r);
        }
        dc.setPenWidth(1);
    }
}
