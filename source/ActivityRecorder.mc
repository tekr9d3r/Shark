import Toybox.ActivityRecording;
import Toybox.Activity;
import Toybox.FitContributor;
import Toybox.Lang;

// Wraps the FIT recording so the whole swim lands in Garmin Connect as a
// normal open-water swim, plus two custom fields for the parts of the game
// the standard FIT record has no room for:
//
//   shark_gap     per second - a graph of the hunt in Garmin Connect, a line
//                 falling toward zero.
//   survived      per session - seconds you lasted after the shark was
//                 released, the number to beat next warm-up.
class ActivityRecorder {

    // Field ids only have to be unique within this app.
    const FIELD_GAP = 0;
    const FIELD_SURVIVED = 1;

    private var _session as ActivityRecording.Session?;
    private var _gapField as FitContributor.Field?;
    private var _survivedField as FitContributor.Field?;

    function start() as Void {
        if (_session != null) {
            return;
        }
        _session = ActivityRecording.createSession({
            :name => "Shark",
            :sport => Activity.SPORT_SWIMMING,
            :subSport => Activity.SUB_SPORT_OPEN_WATER
        });
        createFields();
        (_session as ActivityRecording.Session).start();
    }

    // Custom FIT fields are a best-effort extra: if a device refuses them
    // the swim itself must still record.
    private function createFields() as Void {
        var session = _session;
        if (session == null) {
            return;
        }
        try {
            _gapField = session.createField("shark_gap", FIELD_GAP, FitContributor.DATA_TYPE_UINT16, {
                :mesgType => FitContributor.MESG_TYPE_RECORD,
                :units => "m"
            });
            _survivedField = session.createField("survived", FIELD_SURVIVED, FitContributor.DATA_TYPE_UINT32, {
                :mesgType => FitContributor.MESG_TYPE_SESSION,
                :units => "s"
            });
        } catch (ex) {
            _gapField = null;
            _survivedField = null;
        }
    }

    function recordGap(gapMeters as Float) as Void {
        var field = _gapField;
        if (field == null) {
            return;
        }
        var g = gapMeters;
        if (g < 0.0) {
            g = 0.0;
        } else if (g > 65000.0) {
            g = 65000.0;
        }
        try {
            field.setData(g.toNumber());
        } catch (ex) {
        }
    }

    function recordSurvived(seconds as Float) as Void {
        var field = _survivedField;
        if (field == null) {
            return;
        }
        try {
            field.setData(((seconds < 0.0) ? 0.0 : seconds).toNumber());
        } catch (ex) {
        }
    }

    function stop() as Void {
        var session = _session;
        if (session == null) {
            return;
        }
        if (session.isRecording()) {
            session.stop();
        }
        session.save();
        clear();
    }

    // Used by "Delete Activity" - throws the recording away.
    function discard() as Void {
        var session = _session;
        if (session == null) {
            return;
        }
        if (session.isRecording()) {
            session.stop();
        }
        session.discard();
        clear();
    }

    private function clear() as Void {
        _session = null;
        _gapField = null;
        _survivedField = null;
    }
}
