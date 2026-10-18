using Toybox.Timer;
using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Toybox.Time as Time;

//! Race start countdown.
//!
//! Buzz pattern (minutes and seconds left on the display):
//!   4:00 x4, 3:00 x3, 2:00 x2, 1:00 x1, 0:30 x3, 0:20 x2, 0:10 x1.
//!   Start (5:00) and the gun (0) are silent.
//!
//! Timing is unchanged from the original app: the display drops one second as
//! soon as Start is pressed, so the gun comes ~1 s early (deliberately kept).
class CountDown {

    var app = null;

    // Timers
    var myTimer = null;
    var timerEnd = null;

    // Status
    var timerComplete = false;
    var timerRunning = false;

    // Properties
    var secLeft = 0;
    var raceStartTime = null;

    // How long "START" stays on screen after the gun (ms)
    const START_SCREEN_MS = 5000;

    function initialize(sailingapp) {
        app = sailingapp.weak();
    }

    function isTimerComplete() {
        return timerComplete;
    }

    function isTimerRunning() {
        return timerRunning;
    }

    function secondsLeft() {
        return secLeft;
    }

    function startTime() {
        return raceStartTime;
    }

    function startTimer() {
        if (timerRunning == true) {
            return;
        }
        var sailingApp = app.get();
        if (sailingApp == null) {
            return;
        }
        // A new sequence clears any START screen still showing
        stopStartScreenTimer();
        secLeft = sailingApp.getDefaultTimerCount() * 60;

        updateTimer();

        myTimer = new Timer.Timer();
        myTimer.start(method(:timerCallback), 1000, true);

        timerRunning = true;
    }

    //! Number of short buzzes for the moment `s` seconds are left
    function buzzesFor(s) {
        if (s >= 60 && s <= 240 && (s % 60) == 0) {
            return s / 60;          // 4:00 -> 4 ... 1:00 -> 1
        }
        if (s == 30) {
            return 3;
        }
        if (s == 20) {
            return 2;
        }
        if (s == 10) {
            return 1;
        }
        return 0;
    }

    function finishCountdown() {
        var sailingApp = app.get();
        if (sailingApp != null) {
            sailingApp.addLap();
        }
        raceStartTime = Time.now();
        stopMainTimer();
        timerRunning = false;
        // Show START for a few seconds, silently, then go back to speed
        timerComplete = true;
        timerEnd = new Timer.Timer();
        timerEnd.start(method(:onStartScreenDone), START_SCREEN_MS, false);
        Ui.requestUpdate();
    }

    function timerCallback() as Void {
        var sailingApp = app.get();
        if (sailingApp == null) {
            stopMainTimer();
            timerRunning = false;
            return;
        }
        if (secLeft > 1) {
            // secLeft - 1 is what the display shows after this tick
            var buzzes = buzzesFor(secLeft - 1);
            if (buzzes > 0) {
                sailingApp.buzzer.buzz(buzzes, true);
            }
            updateTimer();
        } else {
            finishCountdown();
        }
    }

    function updateTimer() {
        secLeft -= 1;
        Ui.requestUpdate();
    }

    function fixTimeUp() {
        if (timerRunning == false) {
            return;
        }
        secLeft = ((secLeft / 60) + 1) * 60;
        buzzConfirm();
        Ui.requestUpdate();
    }

    function fixTimeDown() {
        if (timerRunning == false) {
            return;
        }
        secLeft = (secLeft / 60) * 60;
        buzzConfirm();
        Ui.requestUpdate();
    }

    //! Single vibrate (no tone) to confirm a sync press
    function buzzConfirm() {
        var sailingApp = app.get();
        if (sailingApp != null) {
            sailingApp.buzzer.buzz(1, false);
        }
    }

    function onStartScreenDone() as Void {
        timerEnd = null;
        timerComplete = false;
        Ui.requestUpdate();
    }

    function stopMainTimer() {
        if (myTimer != null) {
            myTimer.stop();
            myTimer = null;
        }
    }

    function stopStartScreenTimer() {
        if (timerEnd != null) {
            timerEnd.stop();
            timerEnd = null;
        }
        timerComplete = false;
    }

    //! Stop/abort the countdown (GPS button while running, or mode switch)
    function cancelTimer() {
        stopMainTimer();
        stopStartScreenTimer();
        timerRunning = false;
        Ui.requestUpdate();
    }

    //! Stop all timers before the app is discarded
    function shutdown() {
        stopMainTimer();
        stopStartScreenTimer();
        timerRunning = false;
    }
}
