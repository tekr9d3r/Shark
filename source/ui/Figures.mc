import Toybox.Graphics;
import Toybox.Math;
import Toybox.Lang;

// The shark and the swimmer, drawn entirely from Dc primitives - ellipses,
// polygons, circles, lines - and never from bitmap art, so they scale
// losslessly from a 208 px Forerunner to a 454 px Venu and fit the 128 KB
// app storage of the tightest device in the target list.
//
// Both figures face right and swim right: the shark behind on the left, you
// ahead on the right, the water between you shrinking.
module Figures {

    // --- shark ------------------------------------------------------------

    // x,y is the body centre; `size` is the body's half-height unit every
    // other proportion is quoted against. The dorsal fin reaches about 1.6
    // sizes above the centre.
    function drawShark(dc as Graphics.Dc, x as Number, y as Number, size as Number, stage as Number, phase as Float) as Void {
        var s = size;
        if (s < 5) {
            s = 5;
        }

        // Tail-driven sway: the body yaws a little, the tail swings further.
        var swing = Math.sin(phase * 1.6);
        var bodyShift = (swing * s * 0.06).toNumber();
        var tailShift = (swing * s * 0.42).toNumber();

        var cx = x + bodyShift;
        var a = (s * 1.5).toNumber();  // body half-length
        var b = (s * 0.58).toNumber(); // body half-height
        if (b < 2) {
            b = 2;
        }

        var bodyColor = Palette.SHARK_BODY;
        var eyeColor = Palette.SHARK_EYE;
        if (stage == SwimConstants.DANGER_STAGE_CLOSING) {
            bodyColor = Palette.SHARK_BODY_CLOSING;
        } else if (stage == SwimConstants.DANGER_STAGE_JAWS) {
            bodyColor = Palette.SHARK_BODY_JAWS;
            eyeColor = Palette.SHARK_EYE_JAWS;
        }
        var jaws = (stage == SwimConstants.DANGER_STAGE_JAWS);

        drawSharkTail(dc, cx - a, y, s, tailShift, bodyColor);
        drawSharkDorsal(dc, cx, y - b, s, bodyColor);
        drawSharkSecondDorsal(dc, cx - (a * 0.62).toNumber(), y - (b * 0.7).toNumber(), s, bodyColor);
        drawSharkPectoral(dc, cx, y + b, s, bodyColor);

        dc.setColor(bodyColor, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(cx, y, a, b);
        drawSharkSnout(dc, cx + a, y, s, bodyColor);

        // Countershading: a darker back on the lit body, then a pale belly
        // tucked into the lower half. Tucked ellipses rather than clipped
        // halves - Dc has no clipping region.
        if (!jaws) {
            dc.setColor(Palette.SHARK_BACK, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(cx - (s * 0.1).toNumber(), y - (b * 0.32).toNumber(), (a * 0.86).toNumber(), (b * 0.55).toNumber());
        }
        dc.setColor(Palette.SHARK_BELLY, Graphics.COLOR_TRANSPARENT);
        var bellyB = (b * 0.34).toNumber();
        if (bellyB >= 1) {
            dc.fillEllipse(cx + (s * 0.05).toNumber(), y + (b * 0.56).toNumber(), (a * 0.7).toNumber(), bellyB);
        }

        drawSharkGills(dc, cx, y, s, b);

        // Eye, with a cold glint once there is room for one.
        var eyeX = cx + (a * 0.55).toNumber();
        var eyeY = y - (b * 0.3).toNumber();
        var eyeR = (s * 0.13).toNumber();
        if (eyeR < 1) {
            eyeR = 1;
        }
        dc.setColor(eyeColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(eyeX, eyeY, eyeR);
        if (eyeR >= 3) {
            dc.setColor(Palette.FOAM, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(eyeX + eyeR / 3, eyeY - eyeR / 3, eyeR / 3);
        }

        if (jaws) {
            drawSharkJaws(dc, cx + a, y, s);
        } else {
            drawSharkMouthLine(dc, cx + a, y, s);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Crescent caudal fin: a swept upper lobe, a shorter lower one, hinged
    // at the tail root so `shift` swings both together.
    function drawSharkTail(dc as Graphics.Dc, rootX as Number, y as Number, s as Number, shift as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var tipX = rootX - (s * 0.8).toNumber() + shift;
        dc.fillPolygon([
            [rootX + (s * 0.15).toNumber(), y - (s * 0.12).toNumber()],
            [tipX, y - (s * 1.05).toNumber()],
            [tipX + (s * 0.25).toNumber(), y - (s * 0.08).toNumber()],
            [tipX + (s * 0.02).toNumber(), y + (s * 0.72).toNumber()],
            [rootX + (s * 0.15).toNumber(), y + (s * 0.12).toNumber()]
        ]);
    }

    // The most recognisable part of the figure, drawn big and raked back.
    function drawSharkDorsal(dc as Graphics.Dc, cx as Number, topY as Number, s as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx + (s * 0.45).toNumber(), topY + (s * 0.14).toNumber()],
            [cx - (s * 0.05).toNumber(), topY - (s * 0.6).toNumber()],
            [cx - (s * 0.42).toNumber(), topY - (s * 1.02).toNumber()],
            [cx - (s * 0.62).toNumber(), topY + (s * 0.14).toNumber()]
        ]);
    }

    function drawSharkSecondDorsal(dc as Graphics.Dc, x as Number, topY as Number, s as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x + (s * 0.12).toNumber(), topY + (s * 0.1).toNumber()],
            [x - (s * 0.15).toNumber(), topY - (s * 0.3).toNumber()],
            [x - (s * 0.2).toNumber(), topY + (s * 0.1).toNumber()]
        ]);
    }

    function drawSharkPectoral(dc as Graphics.Dc, cx as Number, bottomY as Number, s as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx + (s * 0.55).toNumber(), bottomY - (s * 0.15).toNumber()],
            [cx - (s * 0.1).toNumber(), bottomY + (s * 0.7).toNumber()],
            [cx + (s * 0.68).toNumber(), bottomY + (s * 0.08).toNumber()]
        ]);
    }

    // Sharpens the ellipse's blunt front into a conical snout.
    function drawSharkSnout(dc as Graphics.Dc, noseX as Number, y as Number, s as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [noseX - (s * 0.45).toNumber(), y - (s * 0.46).toNumber()],
            [noseX + (s * 0.3).toNumber(), y - (s * 0.12).toNumber()],
            [noseX + (s * 0.38).toNumber(), y + (s * 0.02).toNumber()],
            [noseX - (s * 0.45).toNumber(), y + (s * 0.34).toNumber()]
        ]);
    }

    // Gill slits, skipped below the size where they would smear together.
    function drawSharkGills(dc as Graphics.Dc, cx as Number, y as Number, s as Number, b as Number) as Void {
        if (s < 16) {
            return;
        }
        dc.setColor(Palette.INK, Graphics.COLOR_TRANSPARENT);
        var pen = (s * 0.06).toNumber();
        dc.setPenWidth(pen > 0 ? pen : 1);
        var slitH = (b * 0.55).toNumber();
        for (var i = 0; i < 4; i += 1) {
            var gx = cx + (s * (0.18 + 0.15 * i)).toNumber();
            dc.drawLine(gx, y - slitH / 2, gx - (s * 0.07).toNumber(), y + slitH / 2);
        }
        dc.setPenWidth(1);
    }

    // Closed mouth: a thin grim line under the snout, with the tips of two
    // teeth showing - menacing even at a distance.
    function drawSharkMouthLine(dc as Graphics.Dc, noseX as Number, y as Number, s as Number) as Void {
        if (s < 10) {
            return;
        }
        var x0 = noseX - (s * 0.85).toNumber();
        var y0 = y + (s * 0.3).toNumber();
        var x1 = noseX + (s * 0.15).toNumber();
        var y1 = y + (s * 0.12).toNumber();
        dc.setColor(Palette.INK, Graphics.COLOR_TRANSPARENT);
        var pen = (s * 0.06).toNumber();
        dc.setPenWidth(pen > 0 ? pen : 1);
        dc.drawLine(x0, y0, x1, y1);
        dc.setPenWidth(1);

        var t = (s * 0.12).toNumber();
        if (t >= 2) {
            dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
            for (var i = 1; i <= 2; i += 1) {
                var tx = x0 + ((x1 - x0) * i) / 3;
                var ty = y0 + ((y1 - y0) * i) / 3;
                dc.fillPolygon([[tx - t / 2, ty], [tx + t / 2, ty], [tx, ty + t]]);
            }
        }
    }

    // Jaws stage: the mouth gapes - a dark red wedge with rows of bone teeth
    // top and bottom, a smear of blood on the lower jaw.
    function drawSharkJaws(dc as Graphics.Dc, noseX as Number, y as Number, s as Number) as Void {
        var backX = noseX - (s * 1.0).toNumber();
        var tipTopX = noseX + (s * 0.35).toNumber();
        var topY = y + (s * 0.02).toNumber();
        var jawX = noseX + (s * 0.05).toNumber();
        var jawY = y + (s * 0.72).toNumber();
        var hingeY = y + (s * 0.24).toNumber();

        dc.setColor(Palette.MOUTH, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[backX, hingeY], [tipTopX, topY], [jawX, jawY]]);

        // Lower jaw, in the body's dark colour, hanging open.
        dc.setColor(Palette.SHARK_BODY_JAWS, Graphics.COLOR_TRANSPARENT);
        var jawT = (s * 0.14).toNumber();
        dc.fillPolygon([
            [backX, hingeY],
            [jawX, jawY],
            [jawX - (s * 0.1).toNumber(), jawY + jawT],
            [backX - (s * 0.1).toNumber(), hingeY + jawT]
        ]);

        dc.setColor(Palette.BLOOD, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse((backX + jawX) / 2, (hingeY + jawY) / 2 + jawT / 2, (s * 0.35).toNumber(), (s * 0.07).toNumber() + 1);

        var tw = (s * 0.2).toNumber();
        if (tw < 3) {
            dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(backX, hingeY, tipTopX, topY);
            return;
        }
        var th = (s * 0.3).toNumber();
        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        // Upper row hangs down from the snout's edge.
        for (var i = 0; i < 5; i += 1) {
            var f = (i + 0.5) / 5.0;
            var ux = backX + ((tipTopX - backX) * f).toNumber();
            var uy = hingeY + ((topY - hingeY) * f).toNumber();
            dc.fillPolygon([[ux - tw / 2, uy], [ux + tw / 2, uy], [ux, uy + th]]);
        }
        // Lower row stands up from the jaw.
        for (var j = 0; j < 4; j += 1) {
            var g = (j + 0.6) / 4.6;
            var lx = backX + ((jawX - backX) * g).toNumber();
            var ly = hingeY + ((jawY - hingeY) * g).toNumber();
            dc.fillPolygon([[lx - tw / 2, ly], [lx + tw / 2, ly], [lx, ly - th]]);
        }
    }

    // --- swimmer ----------------------------------------------------------

    // Front-crawl seen from the side. The figure is drawn twice: once a
    // little fatter in a bright rim colour, then in the dark suit on top, so
    // it keeps a clean outline over the black sky and the teal water alike.
    // The yellow cap is the one thing on the screen in that colour, so
    // "which one is me" needs no label.
    function drawSwimmer(dc as Graphics.Dc, x as Number, y as Number, size as Number, stage as Number, phase as Float) as Void {
        var s = size;
        if (s < 5) {
            s = 5;
        }
        var lit = (stage != SwimConstants.DANGER_STAGE_CRUISE);
        var bodyColor = lit ? Palette.SWIM_BODY_LIT : Palette.SWIM_BODY;
        var rim = (s * 0.09).toNumber();
        if (rim < 1) {
            rim = 1;
        }
        var roll = (Math.sin(phase * 2.0) * s * 0.06).toNumber();

        drawKickFoam(dc, x - (s * 2.15).toNumber(), y + roll, s, phase);
        drawSwimmerShapes(dc, x, y + roll, s, phase, Palette.SWIM_RIM, rim);
        drawSwimmerShapes(dc, x, y + roll, s, phase, bodyColor, 0);
        drawSwimmerHead(dc, x, y + roll, s);
        drawSplash(dc, x + (s * 1.4).toNumber(), y + roll, s, phase);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Torso, legs, arm and head silhouette. With `grow` > 0 this is the rim
    // pass: the same shapes fattened by `grow` px in the rim colour.
    function drawSwimmerShapes(dc as Graphics.Dc, x as Number, y as Number, s as Number, phase as Float, color as Graphics.ColorType, grow as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        // Lean torso: broad at the shoulders, tapering to narrow hips, a
        // flat stomach - a swimmer's build rather than an ellipse.
        var torso = [
            [x + (s * 0.72).toNumber(), y - (s * 0.2).toNumber()],   // neck, back
            [x + (s * 0.4).toNumber(), y - (s * 0.27).toNumber()],   // shoulder blade
            [x - (s * 0.5).toNumber(), y - (s * 0.17).toNumber()],   // lower back
            [x - (s * 1.05).toNumber(), y - (s * 0.12).toNumber()],  // glutes
            [x - (s * 1.12).toNumber(), y + (s * 0.06).toNumber()],  // hip
            [x - (s * 0.5).toNumber(), y + (s * 0.1).toNumber()],    // stomach
            [x + (s * 0.35).toNumber(), y + (s * 0.17).toNumber()],  // chest
            [x + (s * 0.74).toNumber(), y + (s * 0.06).toNumber()]   // neck, front
        ] as Array<Graphics.Point2D>;
        dc.fillPolygon(torso);
        if (grow > 0) {
            dc.setPenWidth(grow * 2);
            for (var i = 0; i < torso.size(); i += 1) {
                var p0 = torso[i];
                var p1 = torso[(i + 1) % torso.size()];
                dc.drawLine(p0[0], p0[1], p1[0], p1[1]);
            }
        }

        // Flutter kick: two long thin legs scissoring from the hip.
        var hipX = x - (s * 1.05).toNumber();
        var kick = (Math.sin(phase * 4.0) * s * 0.28).toNumber();
        var legPen = (s * 0.15).toNumber() + grow * 2;
        dc.setPenWidth(legPen > 0 ? legPen : 1);
        dc.drawLine(hipX, y, hipX - (s * 1.05).toNumber(), y + kick);
        dc.drawLine(hipX, y, hipX - (s * 1.0).toNumber(), y - kick);

        // Front crawl: the hand leaves the water at the hip, swings forward
        // over the top, enters ahead of the head, then pulls back under the
        // body - clockwise on screen. The underwater pull is a flatter arc,
        // since the arm stays close under the swimmer.
        var shoulderX = x + (s * 0.45).toNumber();
        var shoulderY = y - (s * 0.08).toNumber();
        var angle = Math.PI - phase * 2.0; // starts behind, sweeps over the top
        var reach = s * 1.15;
        var lift = Math.sin(angle);
        var handX = shoulderX + (Math.cos(angle) * reach).toNumber();
        var handY = shoulderY - (lift * reach * ((lift > 0.0) ? 0.85 : 0.4)).toNumber();
        // An elbow bent high on the recovery, nearly straight on the pull.
        var elbowX = (shoulderX + handX) / 2 - (Math.cos(angle) * s * 0.05).toNumber();
        var elbowY = (shoulderY + handY) / 2 - ((lift > 0.0) ? (lift * s * 0.22).toNumber() : 0);
        var armPen = (s * 0.15).toNumber() + grow * 2;
        dc.setPenWidth(armPen > 0 ? armPen : 1);
        dc.drawLine(shoulderX, shoulderY, elbowX, elbowY);
        dc.drawLine(elbowX, elbowY, handX, handY);
        dc.setPenWidth(1);
        var handR = (s * 0.11).toNumber() + grow;
        if (handR >= 1) {
            dc.fillCircle(handX, handY, handR);
        }

        // Head, a little smaller than before so the proportions read human.
        dc.fillCircle(x + (s * 1.02).toNumber(), y - (s * 0.08).toNumber(), headRadius(s) + grow);
    }

    function headRadius(s as Number) as Number {
        var r = (s * 0.34).toNumber();
        return (r < 2) ? 2 : r;
    }

    // The cap covers the whole head; only the face shows at the front-low
    // side, with goggles on it and the strap running back across the cap.
    function drawSwimmerHead(dc as Graphics.Dc, x as Number, y as Number, s as Number) as Void {
        var r = headRadius(s);
        var hx = x + (s * 1.02).toNumber();
        var hy = y - (s * 0.08).toNumber();

        dc.setColor(Palette.SWIM_CAP, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(hx, hy, r);
        if (r < 4) {
            return;
        }

        // Face: the uncapped front-lower quarter of the head.
        var faceX = hx + (r * 0.5).toNumber();
        var faceY = hy + (r * 0.42).toNumber();
        dc.setColor(Palette.SWIM_BODY, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(faceX, faceY, (r * 0.55).toNumber(), (r * 0.5).toNumber());

        var pen = (r * 0.18).toNumber();
        dc.setPenWidth(pen > 0 ? pen : 1);
        // Cap stripe, front to crown.
        dc.setColor(Palette.SWIM_CAP_STRIPE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(hx - (r * 0.75).toNumber(), hy + (r * 0.1).toNumber(),
            hx + (r * 0.2).toNumber(), hy - (r * 0.85).toNumber());
        // Goggle strap round the back of the head.
        dc.setColor(Palette.INK, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(hx - (r * 0.95).toNumber(), hy + (r * 0.05).toNumber(),
            faceX, faceY - (r * 0.12).toNumber());
        dc.setPenWidth(1);
        dc.setColor(Palette.GOGGLE, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(faceX + (r * 0.15).toNumber(), faceY - (r * 0.12).toNumber(),
            (r * 0.3).toNumber(), (r * 0.18).toNumber() + 1);
    }

    // White water churned up by the kick, trailing behind the feet.
    function drawKickFoam(dc as Graphics.Dc, x as Number, y as Number, s as Number, phase as Float) as Void {
        dc.setColor(Palette.FOAM, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 4; i += 1) {
            var t = phase * 3.0 + i * 1.7;
            var r = (s * (0.09 + 0.05 * ((i + 1) % 3))).toNumber();
            if (r < 1) {
                r = 1;
            }
            var dx = (s * (0.15 + 0.3 * i)).toNumber();
            var dy = (Math.sin(t) * s * 0.18).toNumber();
            dc.fillCircle(x - dx, y - (s * 0.1).toNumber() + dy, r);
        }
    }

    // --- fin ----------------------------------------------------------------

    // Just a dorsal fin slicing the surface: lit front face, shaded back face,
    // a foam rim, and a wake peeling off behind it. `dir` is +1 moving right,
    // -1 moving left, so the fin rakes and the wake trails the right way.
    function drawFin(dc as Graphics.Dc, x as Number, surfaceY as Number, s as Number, dir as Number, phase as Float) as Void {
        var tipX = x - dir * (s * 0.45).toNumber();
        var tipY = surfaceY - s;
        var frontX = x + dir * (s * 0.5).toNumber();
        var backX = x - dir * (s * 0.55).toNumber();
        var rim = (s * 0.08).toNumber();
        if (rim < 1) {
            rim = 1;
        }

        // Wake: two foam lines fanning back from the base, and a bow ripple.
        var wakeLen = (s * 1.1).toNumber();
        var spread = (s * 0.18).toNumber() + (Math.sin(phase * 1.5) * s * 0.05).toNumber();
        dc.setColor(Palette.FOAM, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(rim + 1);
        dc.drawLine(backX, surfaceY, backX - dir * wakeLen, surfaceY - spread);
        dc.drawLine(backX, surfaceY + rim, backX - dir * wakeLen, surfaceY + spread + rim);
        dc.setPenWidth(1);
        dc.fillEllipse(frontX, surfaceY, (s * 0.3).toNumber(), (s * 0.1).toNumber() + 1);

        // Foam rim, then the two faces.
        dc.fillPolygon([[frontX + dir * rim, surfaceY + rim], [tipX, tipY - rim * 2], [backX - dir * rim, surfaceY + rim]]);
        dc.setColor(Palette.FIN_LIT, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[frontX, surfaceY], [tipX, tipY], [backX, surfaceY]]);
        var midX = (frontX + backX) / 2 - dir * (s * 0.05).toNumber();
        dc.setColor(Palette.FIN_SHADE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[midX, surfaceY], [tipX, tipY], [backX, surfaceY]]);

        // A notch of white water hugging the base.
        dc.setColor(Palette.FOAM, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(x, surfaceY + rim, (s * 0.55).toNumber(), rim + 1);
    }

    // Bow wave off the head.
    function drawSplash(dc as Graphics.Dc, frontX as Number, y as Number, s as Number, phase as Float) as Void {
        var r = (s * 0.11).toNumber();
        if (r < 1) {
            return;
        }
        dc.setColor(Palette.FOAM, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 3; i += 1) {
            var t = phase * 1.4 + i * 0.9;
            var dx = (s * (0.15 + 0.22 * i)).toNumber();
            var dy = (Math.sin(t) * s * 0.2).toNumber();
            dc.fillCircle(frontX + dx, y - (s * 0.15).toNumber() + dy, r);
        }
    }
}
