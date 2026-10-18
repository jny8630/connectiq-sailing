using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Math as Math;
using Toybox.Position as Position;
using Toybox.Application as App;

class SailingView extends Ui.View {

    var countDown = null;

    // Graphical
    var screenHeight;
    var screenWidth;
    var minDim;
    var centerX;
    var centerY;
    var ringThickness;
    var ringRadius;
    var sec = 0;
    var min = 0;

    // Strings
    var accuracyStr = "0";
    var headingStr = "-";
    var headingOnlyStr = "-";
    var speedStr = "-";
    var unitsOffset = 0;
    var countDownStr = "";

    // Data
    var speedFloat = 0.0;
    var accuracy = Position.QUALITY_NOT_AVAILABLE;

    // Constants
    const SPEED_UNIT = "kts";
    const METERS_PER_NM = 1852.0;

    // Device settings
    var deviceSettings;

    function initialize(countdown) {
        View.initialize();
        countDown = countdown.weak();

        // Get device information
        deviceSettings = Sys.getDeviceSettings();
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        if(screenHeight < screenWidth){
            minDim = screenHeight;
        }else{
            minDim = screenWidth;
        }
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        ringThickness = (minDim / 2) * 0.2;
        if (ringThickness < 4) {
            ringThickness = 4;
        }
        ringRadius = (minDim / 2) - (ringThickness / 2);
    }

    function updateTimer(countdownObj) {
        var secLeft = countdownObj.secondsLeft();

        sec = secLeft % 60;
        min = secLeft / 60;

        //format
        if(min > 0) {
            countDownStr = min.format("%d") + ":" + sec.format("%02d");
        }else {
            countDownStr = sec.format("%d");
        }
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        var now = Time.now();
        var countdownObj = countDown.get();

        dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        dc.clear();
        dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT );

        if (countdownObj != null && countdownObj.isTimerRunning()) {
            updateTimer(countdownObj);
            drawCountdownRing(dc);
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            dc.drawText( centerX, centerY - (Gfx.getFontHeight(Gfx.FONT_NUMBER_THAI_HOT) / 2), Gfx.FONT_NUMBER_THAI_HOT, countDownStr, Gfx.TEXT_JUSTIFY_CENTER );

        } else if (countdownObj != null && countdownObj.isTimerComplete()) {
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_BLACK );
            dc.drawText( centerX, centerY - (Gfx.getFontHeight(Gfx.FONT_LARGE) / 2), Gfx.FONT_LARGE, "START", Gfx.TEXT_JUSTIFY_CENTER );

        } else if (accuracy < Position.QUALITY_USABLE) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - Gfx.getFontAscent(Gfx.FONT_MEDIUM) - Gfx.getFontDescent(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, "Waiting for", Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText(centerX, centerY, Gfx.FONT_MEDIUM, "GPS signal ("+accuracyStr+")", Gfx.TEXT_JUSTIFY_CENTER);

        } else if (App.getApp().isFcCruiseMode()) {
            drawFcCruise(dc);

        } else {
            drawRace(dc, now, countdownObj);
        }
    }

    //! Race screen: time of day, speed, heading, race clock after the gun
    function drawRace(dc, now, countdownObj) {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);

        var nowInfo = Time.Gregorian.info(now, Time.FORMAT_MEDIUM);
        var nowString = Lang.format("$1$:$2$:$3$",
            [nowInfo.hour.format("%02d"), nowInfo.min.format("%02d"), nowInfo.sec.format("%02d")]);

        if (speedFloat > 10.0){
            unitsOffset = 5;
        } else {
            unitsOffset = 0;
        }
        var yOffset = screenHeight / 20;
        if (self has :getSubscreen) {
            var subscreen = getSubscreen();

            // If we are on the instinct (but not crossover), change the display
            if(deviceSettings.screenShape == Sys.SCREEN_SHAPE_SEMI_OCTAGON)
            {
                dc.drawText((screenWidth / 3), 40, Gfx.FONT_MEDIUM , nowString, Gfx.TEXT_JUSTIFY_CENTER);
                drawInstinctSpeedAndHeading(dc, subscreen);
            }
        } else {
            dc.drawText((screenWidth / 2), yOffset, Gfx.FONT_TINY , nowString, Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText((screenWidth / 2), yOffset + Gfx.getFontAscent(Gfx.FONT_MEDIUM), Gfx.FONT_NUMBER_THAI_HOT, speedStr, Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText((screenWidth / 2), yOffset + Gfx.getFontAscent(Gfx.FONT_NUMBER_THAI_HOT) + Gfx.getFontAscent(Gfx.FONT_MEDIUM) + 40, Gfx.FONT_MEDIUM, headingStr, Gfx.TEXT_JUSTIFY_CENTER);
        }

        var raceStartTime = null;
        if (countdownObj != null) {
            raceStartTime = countdownObj.startTime();
        }

        if(raceStartTime != null){
            //print running timer
            var raceTime = now.subtract(raceStartTime);
            var raceTimeStr = secToStr(raceTime.value());
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText((screenWidth / 2), yOffset + Gfx.getFontHeight(Gfx.FONT_NUMBER_THAI_HOT) + Gfx.getFontDescent(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, raceTimeStr, Gfx.TEXT_JUSTIFY_CENTER);
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        }
    }

    //! FC Cruise screen: helm timer, speed, heading, total time and distance
    function drawFcCruise(dc) {
        var app = App.getApp();
        var helmStr = "--:--";
        if (app.helmTimer != null && app.helmTimer.isRunning()) {
            var left = app.helmTimer.secondsLeft();
            helmStr = (left / 60).format("%d") + ":" + (left % 60).format("%02d");
        }
        var totalStr = secToStr(app.getTotalTime());
        var meters = app.getTotalDistance();
        if (meters != null) {
            totalStr += "  " + (meters / METERS_PER_NM).format("%0.2f") + "nm";
        }

        if (speedFloat > 10.0){
            unitsOffset = 5;
        } else {
            unitsOffset = 0;
        }
        var tinyH = Gfx.getFontHeight(Gfx.FONT_TINY);
        var bottomY = screenHeight - tinyH - 6;

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        if ((self has :getSubscreen) && deviceSettings.screenShape == Sys.SCREEN_SHAPE_SEMI_OCTAGON) {
            // Instinct: helm timer where the race clock-of-day sits
            dc.drawText((screenWidth / 3), 40 - tinyH, Gfx.FONT_TINY, "FC CRUISE", Gfx.TEXT_JUSTIFY_CENTER);
            dc.drawText((screenWidth / 3), 40, Gfx.FONT_MEDIUM, helmStr, Gfx.TEXT_JUSTIFY_CENTER);
            drawInstinctSpeedAndHeading(dc, getSubscreen());
        } else {
            var y = screenHeight / 20;
            dc.drawText(centerX, y, Gfx.FONT_TINY, "FC CRUISE", Gfx.TEXT_JUSTIFY_CENTER);
            y += tinyH;
            dc.drawText(centerX, y, Gfx.FONT_MEDIUM, helmStr, Gfx.TEXT_JUSTIFY_CENTER);
            y += Gfx.getFontHeight(Gfx.FONT_MEDIUM);
            dc.drawText(centerX, y, Gfx.FONT_NUMBER_HOT, speedStr, Gfx.TEXT_JUSTIFY_CENTER);
            y += Gfx.getFontHeight(Gfx.FONT_NUMBER_HOT);
            if (y + Gfx.getFontHeight(Gfx.FONT_SMALL) <= bottomY) {
                dc.drawText(centerX, y, Gfx.FONT_SMALL, headingStr, Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
        dc.drawText(centerX, bottomY, Gfx.FONT_TINY, totalStr, Gfx.TEXT_JUSTIFY_CENTER);
    }

    //! Instinct layout shared by both modes: big speed, heading in the subscreen
    function drawInstinctSpeedAndHeading(dc, subscreen) {
        dc.drawText((screenWidth / 2), (screenHeight / 2), Gfx.FONT_NUMBER_THAI_HOT, speedStr, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText((3 * (screenWidth / 4)) + unitsOffset, (screenHeight / 2), Gfx.FONT_MEDIUM, SPEED_UNIT, Gfx.TEXT_JUSTIFY_LEFT);
        if (subscreen != null) {
            dc.drawText((subscreen.x + (subscreen.width / 2) + 4), (subscreen.y + (subscreen.height/4)), Gfx.FONT_MEDIUM, headingOnlyStr, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }

    //! Countdown ring: grey track plus a green arc for the current minute.
    //! drawArc only, no polygon allocations (ported from upstream's OOM fix).
    function drawCountdownRing(dc) {
        var progress = sec / 60.0;
        if (progress < 0) {
            progress = 0;
        } else if (progress > 1) {
            progress = 1;
        }

        dc.setPenWidth(ringThickness);

        // Full-circle track, split to avoid the 360-degree drawArc quirk
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, ringRadius, Gfx.ARC_CLOCKWISE, 90, -90);
        dc.drawArc(centerX, centerY, ringRadius, Gfx.ARC_CLOCKWISE, -90, 90);

        if (progress > 0) {
            // From 12 o'clock, clockwise
            var arcLength = progress * 360.0;
            var degreeStart = 90;
            var degreeEnd = 90 - arcLength;

            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
            if (arcLength >= 360) {
                dc.drawArc(centerX, centerY, ringRadius, Gfx.ARC_CLOCKWISE, 90, -90);
                dc.drawArc(centerX, centerY, ringRadius, Gfx.ARC_CLOCKWISE, -90, 90);
            } else if (arcLength > 180) {
                dc.drawArc(centerX, centerY, ringRadius, Gfx.ARC_CLOCKWISE, degreeStart, degreeStart - 180);
                dc.drawArc(centerX, centerY, ringRadius, Gfx.ARC_CLOCKWISE, degreeStart - 180, degreeEnd);
            } else {
                dc.drawArc(centerX, centerY, ringRadius, Gfx.ARC_CLOCKWISE, degreeStart, degreeEnd);
            }
        }
        dc.setPenWidth(1);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

    //! GPS update. Any field can be missing (no fix yet), so each is checked.
    function onPosition(info) {
        if (info == null) {
            return;
        }

        if (info.accuracy != null) {
            accuracy = info.accuracy;
            accuracyStr = accuracy.format("%d");
        }

        if (info.heading != null) {
            var heading = info.heading;
            headingStr = headingToStr(heading);
            var headingDeg = ((180 * heading ) /  Math.PI);
            if (headingDeg < 0) {
                headingDeg += 360;
            }
            headingOnlyStr = headingDeg.format("%d") + "°";
            headingStr += " - " + headingDeg.format("%d");
        } else {
            headingStr = "-";
            headingOnlyStr = "-";
        }

        if (info.speed != null) {
            speedFloat = info.speed * 1.943844492;
            speedStr = speedFloat.format("%0.1f");
        } else {
            speedFloat = 0.0;
            speedStr = "-";
        }
    }

    function headingToStr(heading){
        var sixteenthPI = Math.PI / 16.0;
        if (heading >= 0 and heading < sixteenthPI){
            return "N";
        }else if (heading > 0 and heading < (3 * sixteenthPI)){
           return "NNE";
        }else if (heading > 0 and heading < (5 * sixteenthPI)){
           return "NE";
        }else if (heading > 0 and heading < (7 * sixteenthPI)){
           return "ENE";
        }else if (heading > 0 and heading < (9 * sixteenthPI)){
           return "E";
        }else if (heading > 0 and heading < (11 * sixteenthPI)){
           return "ESE";
        }else if (heading > 0 and heading < (13 * sixteenthPI)){
           return "SE";
        }else if (heading > 0 and heading < (15 * sixteenthPI)){
           return "SSE";
        }else if (heading > 0){
           return "S";
        }else if (heading < 0 and heading < (-15 * sixteenthPI)){
           return "S";
        }else if (heading < 0 and heading < (-13 * sixteenthPI)){
           return "SSW";
        }else if (heading < 0 and heading < (-11 * sixteenthPI)){
           return "SW";
        }else if (heading < 0 and heading < (-9 * sixteenthPI)){
           return "WSW";
        }else if (heading < 0 and heading < (-7 * sixteenthPI)){
           return "W";
        }else if (heading < 0 and heading < (-5 * sixteenthPI)){
           return "WNW";
        }else if (heading < 0 and heading < (-3 * sixteenthPI)){
           return "NW";
        }else if (heading < 0 and heading < -sixteenthPI){
           return "NNW";
        }else {
            return "N";
        }
    }

    //! hh:mm:ss. Accepts any numeric type or null (upstream race-time crash fix).
    function secToStr(raceTime){
        var total = 0;
        if (raceTime != null) {
            total = raceTime.toNumber();
        }
        if (total < 0) {
            total = 0;
        }
        var raceSec = (total % 60).format("%02d");
        var raceMin = ((total / 60) % 60).format("%02d");
        var raceHours = ((total / 3600) % 60).format("%02d");

        return ""+raceHours+":"+raceMin+":"+raceSec;
    }
}
