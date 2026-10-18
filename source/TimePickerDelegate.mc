using Toybox.WatchUi;
using Toybox.Application;
using Toybox.System;
using Toybox.Lang;

//! Responds to a time picker selection or cancellation
class TimePickerDelegate extends WatchUi.PickerDelegate {

    //! Constructor
    private var _helm as Lang.Boolean = false;

    //! @param helm true when the picker sets the FC Cruise helm period
    public function initialize(helm as Lang.Boolean) {
        PickerDelegate.initialize();
        _helm = helm;
    }

    //! Handle a cancel event from the picker
    //! @return true if handled, false otherwise
    public function onCancel() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    //! Handle a confirm event from the picker
    //! @param values The values chosen in the picker
    //! @return true if handled, false otherwise
    public function onAccept(values as Lang.Array) as Lang.Boolean {
        if (_helm) {
            Application.getApp().setHelmTimerCount(values[0]);
        } else {
            Application.getApp().setDefaultTimerCount(values[0]);
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
