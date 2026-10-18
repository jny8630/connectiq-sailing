using Toybox.Timer;
using Toybox.WatchUi as Ui;
using Toybox.Time as Time;

//! FC Cruise helm-change timer.
//!
//! Counts down the helm period (default 20 min), buzzes twice when 2 minutes
//! remain, and at zero silently starts the next period by itself. Runs off the
//! wall clock so it doesn't drift over a long sail.
class HelmTimer {

    var app = null;
    var timer = null;
    var endSec = 0;          // epoch seconds when the current period ends
    var running = false;
    var warned = false;      // 2-minute buzz already given this period

    const WARN_SECONDS = 120;

    function initialize(sailingapp) {
        app = sailingapp.weak();
    }

    function isRunning() {
        return running;
    }

    function periodSeconds() {
        var sailingApp = app.get();
        if (sailingApp == null) {
            return 20 * 60;
        }
        return sailingApp.getHelmTimerCount() * 60;
    }

    //! Seconds left in the current period (0 when stopped)
    function secondsLeft() {
        if (!running) {
            return 0;
        }
        var left = endSec - Time.now().value();
        if (left < 0) {
            left = 0;
        }
        return left;
    }

    function start() {
        if (running) {
            return;
        }
        endSec = Time.now().value() + periodSeconds();
        warned = false;
        timer = new Timer.Timer();
        timer.start(method(:onTick), 1000, true);
        running = true;
        Ui.requestUpdate();
    }

    function stop() {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
        running = false;
        Ui.requestUpdate();
    }

    function startStop() {
        if (running) {
            stop();
        } else {
            start();
        }
    }

    //! Up/Down while running: add or remove a minute from the current period
    function adjust(minutes) {
        if (!running) {
            return;
        }
        var now = Time.now().value();
        endSec += minutes * 60;
        if (endSec < now + 1) {
            endSec = now + 1;
        }
        if (endSec - now > WARN_SECONDS) {
            warned = false;
        }
        var sailingApp = app.get();
        if (sailingApp != null) {
            sailingApp.buzzer.buzz(1, false);
        }
        Ui.requestUpdate();
    }

    function onTick() as Void {
        var sailingApp = app.get();
        if (sailingApp == null) {
            stop();
            return;
        }
        var left = endSec - Time.now().value();
        // Two buzzes at 2:00 left (skipped when the period is 2 min or shorter)
        if (!warned && left <= WARN_SECONDS && left > 0 && periodSeconds() > WARN_SECONDS) {
            warned = true;
            sailingApp.buzzer.buzz(2, true);
        }
        if (left <= 0) {
            // Next helm period starts by itself
            endSec += periodSeconds();
            var now = Time.now().value();
            if (endSec <= now) {
                endSec = now + periodSeconds();
            }
            warned = false;
        }
        Ui.requestUpdate();
    }
}
