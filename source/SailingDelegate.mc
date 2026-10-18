using Toybox.WatchUi as Ui;
using Toybox.Application as App;


class SailingDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKey(evt){
        if (evt.getKey() == WatchUi.KEY_ESC){
            pushStopMenu();
            return true;
        }
        return false;
    }

    function pushStopMenu() {
        Ui.pushView(new Rez.Menus.StopMenu(), new ExitMenuDelegate(), Ui.SLIDE_UP);
        Ui.requestUpdate();
    }

    //! GPS button: start / stop the race countdown, or the helm timer in FC Cruise
    function onSelect(){
            App.getApp().startStopTimer();
            Ui.requestUpdate();
            return true;
    }

    function onBack(){
            pushStopMenu();
            return true;
    }

    function onMenu(){
            Ui.pushView(buildMainMenu(), new SailingMenuDelegate(), Ui.SLIDE_UP);
            Ui.requestUpdate();
            return true;
    }

    //! Menu is built in code so labels can show the current mode and alarm state
    function buildMainMenu() {
        var app = App.getApp();
        var menu = new Ui.Menu();
        menu.setTitle("Menu");
        if (app.isFcCruiseMode()) {
            menu.addItem("Start helm timer", :start_timer);
            menu.addItem("Set helm timer", :set_timer);
        } else {
            menu.addItem("Start timer", :start_timer);
            menu.addItem("Set timer", :set_timer);
        }
        if (app.getAlarms()) {
            menu.addItem("Alarms: on", :set_alarms);
        } else {
            menu.addItem("Alarms: off", :set_alarms);
        }
        if (app.isFcCruiseMode()) {
            menu.addItem("Race mode", :switch_mode);
        } else {
            menu.addItem("FC Cruise mode", :switch_mode);
        }
        return menu;
    }

    //! Up / Down: sync the race countdown (or adjust the helm timer) by a minute
    function onPreviousPage(){
            App.getApp().fixTimeUp();
            return true;
    }

    function onNextPage(){
            App.getApp().fixTimeDown();
            return true;
    }
}
