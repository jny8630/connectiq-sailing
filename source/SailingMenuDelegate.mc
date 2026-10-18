using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class SailingMenuDelegate extends Ui.MenuInputDelegate {

    function onMenuItem(item) {
        var app = App.getApp();
        if (item == :start_timer) {
            app.startTimer();
        } else if (item == :set_timer) {
            if (Ui has :Picker) {
                var helm = app.isFcCruiseMode();
                Ui.pushView(new TimePicker(helm), new TimePickerDelegate(helm), Ui.SLIDE_UP);
            }
        } else if (item == :set_alarms) {
            app.setAlarms(! app.getAlarms());
        } else if (item == :switch_mode) {
            if (app.isFcCruiseMode()) {
                app.setSailingMode(SAILING_MODE_RACE);
            } else {
                app.setSailingMode(SAILING_MODE_FC_CRUISE);
            }
        }
    }

    function initialize() {
        MenuInputDelegate.initialize();
    }
}
