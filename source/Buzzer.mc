using Toybox.Attention as Attention;
using Toybox.Application as App;

//! Short vibrate/tone bursts shared by the race countdown and the helm timer.
//! Profiles are built once so a buzz never allocates (low-memory watches).
class Buzzer {

    var hasVibrate = false;
    var hasTone = false;
    var vibes = null;   // vibes[n-1] = n short buzzes
    var tones = null;

    function initialize() {
        hasVibrate = (Attention has :vibrate);
        hasTone = (Attention has :ToneProfile) && (Attention has :playTone);
        if (hasVibrate) {
            var vibeOn = new Attention.VibeProfile(80, 200);
            var vibeOff = new Attention.VibeProfile(0, 50);
            vibes = [
                [vibeOn, vibeOff],
                [vibeOn, vibeOff, vibeOn, vibeOff],
                [vibeOn, vibeOff, vibeOn, vibeOff, vibeOn, vibeOff],
                [vibeOn, vibeOff, vibeOn, vibeOff, vibeOn, vibeOff, vibeOn, vibeOff]
            ];
        }
        if (hasTone) {
            var toneOn = new Attention.ToneProfile(2500, 200);
            var toneOff = new Attention.ToneProfile(0, 50);
            tones = [
                [toneOn, toneOff],
                [toneOn, toneOff, toneOn, toneOff],
                [toneOn, toneOff, toneOn, toneOff, toneOn, toneOff],
                [toneOn, toneOff, toneOn, toneOff, toneOn, toneOff, toneOn, toneOff]
            ];
        }
    }

    //! Buzz `times` short pulses (1-4). Silent when alarms are turned off.
    function buzz(times, withTone) {
        if (App.getApp().getAlarms() == false) {
            return;
        }
        if (times < 1) {
            return;
        }
        if (times > 4) {
            times = 4;
        }
        if (hasVibrate) {
            Attention.vibrate(vibes[times - 1]);
        }
        if (hasTone && withTone) {
            Attention.playTone({:toneProfile=>tones[times - 1]});
        }
    }
}
