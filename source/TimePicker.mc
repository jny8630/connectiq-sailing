using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Lang;


//! Picker that allows the user to choose a time
class TimePicker extends WatchUi.Picker {

    //! Constructor
    //! @param helm true to set the FC Cruise helm period, false for the race countdown
    public function initialize(helm as Lang.Boolean) {
        var label = "Time";
        var factory = new TimeFactory(0, 30, 1, {});
        var time = Application.getApp().getDefaultTimerCount();
        if (helm) {
            label = "Helm min";
            factory = new TimeFactory(1, 60, 1, {});
            time = Application.getApp().getHelmTimerCount();
        }
        var title = new WatchUi.Text({
            :text=>label,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM,
            :color=>Graphics.COLOR_WHITE});

        var index = factory.getIndex(time);

        Picker.initialize({:title=>title, :pattern=>[factory], :defaults=>[index]});
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }
}
