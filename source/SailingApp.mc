using Toybox.Application as App;
using Toybox.Application.Properties;
using Toybox.WatchUi;
using Toybox.Timer as Timer;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Position as Position;
using Toybox.System as Sys;

enum {
    SAILING_MODE_RACE,
    SAILING_MODE_FC_CRUISE
}

class SailingApp extends App.AppBase {

    var session = null;
    var sailingView = null;

    var gpsSetupTimer = null;
    var countDown = null;
    var helmTimer = null;
    var buzzer = null;

    // Not saved: the app always opens in Race mode
    var sailingMode = SAILING_MODE_RACE;

    // get default timer count from properties, if not set return default
    function getDefaultTimerCount() {
        if (! (App has :Properties)) {
            return 5;
        }
        var time = Properties.getValue("time");
        if (time == null || time < 0) {
            return 5;
        }
        return time;
    }

    // set default timer count in properties
    function setDefaultTimerCount(time) {
        if (! (App has :Properties)) {
            return;
        }
        Properties.setValue("time", time);
    }

    //! FC Cruise helm period in minutes
    function getHelmTimerCount() {
        if (! (App has :Properties)) {
            return 20;
        }
        var time = Properties.getValue("helmTime");
        if (time == null || time < 1) {
            return 20;
        }
        return time;
    }

    function setHelmTimerCount(time) {
        if (! (App has :Properties)) {
            return;
        }
        Properties.setValue("helmTime", time);
    }

    function getAlarms() {
        if (! (App has :Properties)) {
            return true;
        }
        var alarms = Properties.getValue("alarms");
        if (alarms == null) {
            return true;
        }
        return alarms;
    }

    function setAlarms(alarms) {
        if (! (App has :Properties)) {
            return;
        }
        Properties.setValue("alarms", alarms);
    }

    function isFcCruiseMode() {
        return sailingMode == SAILING_MODE_FC_CRUISE;
    }

    //! Switch between Race and FC Cruise; stops the other mode's timer
    function setSailingMode(mode) {
        if (mode == SAILING_MODE_FC_CRUISE) {
            if (countDown != null) {
                countDown.cancelTimer();
            }
        } else {
            if (helmTimer != null) {
                helmTimer.stop();
            }
        }
        sailingMode = mode;
        WatchUi.requestUpdate();
    }

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        buzzer = new Buzzer();
        countDown = new CountDown(self);
        helmTimer = new HelmTimer(self);
        gpsSetupTimer = new Timer.Timer();
        gpsSetupTimer.start(method(:startActivityRecording), 1000, true);

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
        stopGpsSetupTimer();
        if (countDown != null) {
            countDown.shutdown();
            countDown = null;
        }
        if (helmTimer != null) {
            helmTimer.stop();
            helmTimer = null;
        }
        sailingView = null;

        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function stopGpsSetupTimer() {
        if (gpsSetupTimer != null) {
            gpsSetupTimer.stop();
            gpsSetupTimer = null;
        }
    }

    function saveAndClose() {
        stopRecording(true);
        Sys.exit();
    }

    function discardAndClose() {
        stopRecording(false);
        Sys.exit();
    }

    //! Menu "Start timer": race countdown, or helm timer in FC Cruise
    function startTimer() {
        if (isFcCruiseMode()) {
            if (helmTimer != null) {
                helmTimer.start();
            }
        } else if (countDown != null) {
            countDown.startTimer();
        }
    }

    //! GPS button: start / stop the timer of the current mode
    function startStopTimer() {
        if (isFcCruiseMode()) {
            if (helmTimer != null) {
                helmTimer.startStop();
            }
            return;
        }
        if (countDown == null) {
            return;
        }
        if (countDown.isTimerRunning() == false) {
            countDown.startTimer();
        } else {
            countDown.cancelTimer();
        }
    }

    function fixTimeUp() {
        if (isFcCruiseMode()) {
            if (helmTimer != null) {
                helmTimer.adjust(1);
            }
        } else if (countDown != null) {
            countDown.fixTimeUp();
        }
    }

    function fixTimeDown() {
        if (isFcCruiseMode()) {
            if (helmTimer != null) {
                helmTimer.adjust(-1);
            }
        } else if (countDown != null) {
            countDown.fixTimeDown();
        }
    }

    //! Return the initial view of your application here
    function getInitialView() {
        sailingView = new SailingView(countDown);
        return [ sailingView, new SailingDelegate() ];
    }

    function onPosition(info as Position.Info) as Void {
        if (sailingView == null) {
            return;
        }
        sailingView.onPosition(info);
        if (countDown == null || countDown.isTimerRunning() == false) {
            WatchUi.requestUpdate();
        }
    }

    //! Polled every second until GPS is usable, then recording starts by itself
    function startActivityRecording() as Void {
        var info = Position.getInfo();
        if (info == null || info.accuracy == null || info.accuracy < Position.QUALITY_USABLE) {
            return;
        }
        stopGpsSetupTimer();
        if (Toybox has :ActivityRecording) {
            if ((session == null) || (session.isRecording() == false)) {
                var version = Sys.getDeviceSettings().monkeyVersion;
                if (version[0] >= 3) {
                    session = ActivityRecording.createSession({:name=>"Sailing", :sport=>Activity.SPORT_SAILING});
                } else {
                    session = ActivityRecording.createSession({:name=>"Sailing", :sport=>Activity.SPORT_GENERIC});
                }
                session.start();
            }
        }
    }

    function addLap() {
        if ((session != null) && session.isRecording()) {
            session.addLap();
        }
    }

    //! Total elapsed activity time in whole seconds, or null
    function getTotalTime() {
        var info = Activity.getActivityInfo();
        if (session == null || info == null || info.elapsedTime == null) {
            return null;
        }
        return (info.elapsedTime / 1000).toNumber();
    }

    //! Total distance in meters, or null
    function getTotalDistance() {
        var info = Activity.getActivityInfo();
        if (session == null || info == null || info.elapsedDistance == null) {
            return null;
        }
        return info.elapsedDistance;
    }

     //! Stop the recording if necessary
    function stopRecording(save) {
        if (Toybox has :ActivityRecording) {
            if (session != null) {
                if (session.isRecording()) {
                    session.stop();
                }
                if (save) {
                    session.save();
                } else {
                    session.discard();
                }
                session = null;
            }
        }
    }
}
