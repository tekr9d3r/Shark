import Toybox.Lang;

// Named anchors for the two screen compositions. Round screens lose their
// corners to the bezel curve so content is inset harder top and bottom;
// rectangular ones can run closer to the edge. Screens ask this for "where
// things go" instead of each recomputing the same geometry inline.
class HudLayout {

    var titleY as Number;
    var bodyStartY as Number;
    var bodyLineHeight as Number;
    var hintY as Number;

    // The band the picture lives in - the water scene on the swim screen,
    // the chip stack on setup, the shark on the result screen.
    var stageTop as Number;
    var stageBottom as Number;

    function initialize(metrics as ScreenMetrics) {
        if (metrics.isRound) {
            // Inset past the fangs on the rim.
            titleY = metrics.px(70);
            stageTop = metrics.px(122);
            stageBottom = metrics.height - metrics.px(112);
            bodyStartY = stageBottom + metrics.px(14);
            bodyLineHeight = metrics.px(30);
            hintY = metrics.height - metrics.px(84);
        } else {
            titleY = metrics.px(56);
            stageTop = metrics.px(100);
            stageBottom = metrics.height - metrics.px(100);
            bodyStartY = stageBottom + metrics.px(12);
            bodyLineHeight = metrics.px(28);
            hintY = metrics.height - metrics.px(80);
        }
    }
}
