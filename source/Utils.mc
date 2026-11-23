import Toybox.Lang;

module Utils {

    function formatClock(totalSeconds as Float) as String {
        var s = totalSeconds.toNumber();
        if (s < 0) {
            s = 0;
        }
        var h = s / 3600;
        var m = (s % 3600) / 60;
        var sec = s % 60;
        if (h > 0) {
            return h.format("%01d") + ":" + m.format("%02d") + ":" + sec.format("%02d");
        }
        return m.format("%01d") + ":" + sec.format("%02d");
    }

    // m:ss from a whole number of seconds - used for the target-pace picker,
    // where the value is exact rather than measured.
    function formatMinSec(totalSeconds as Number) as String {
        var s = (totalSeconds < 0) ? 0 : totalSeconds;
        return (s / 60).format("%01d") + ":" + (s % 60).format("%02d");
    }

    // Swimming's unit is min:sec per 100 m, not per km. Anything slower than
    // a drifting float reads as "not moving" rather than dividing toward
    // infinity, and anything past 9:59 is clamped so the string can't grow
    // wide enough to break the layouts that size around it.
    function speedToPaceString(speedMps as Float) as String {
        if (speedMps <= 0.05) {
            return "--:--";
        }
        var secPer100 = (100.0 / speedMps).toNumber();
        if (secPer100 > 599) {
            return "9:59+";
        }
        return formatMinSec(secPer100);
    }

    // Whole metres for anything under a kilometre, one decimal of a
    // kilometre beyond it - a 4700 m swim reads better as 4.7 km, and the
    // hero readouts have no room for five digits on a 176 px screen.
    function formatDistance(meters as Float) as String {
        if (meters >= 1000.0) {
            return (meters / 1000.0).format("%.1f") + " km";
        }
        return meters.format("%.0f") + " m";
    }
}
