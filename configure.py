#!/usr/bin/env python

# Prey Installer
# By Tomas Pollak (bootlog.org)

import pygtk
pygtk.require('2.0')
import gtk
import os

class PreyConfigurator:
    def entry_toggle_web_service(self, checkbutton, url, api_key, device_key):
        url.set_editable(not checkbutton.get_active())
        api_key.set_editable(checkbutton.get_active())
        device_key.set_editable(checkbutton.get_active())

    def entry_toggle_visibility(self, checkbutton, entry):
        entry.set_visibility(checkbutton.get_active())

    def apply_settings(self, checkbutton, lang, url, api_key, device_key, minutes):
        model = lang.get_model()
        index = lang.get_active()
        language = model[index][0]
        print "Lang: %s" % language
        print "URL: %s" % url.get_text()
        print "API Key: %s" % api_key.get_text()
        print "Device Key: %s" % device_key.get_text()
        print "Time: %s" % minutes.get_value_as_int()
        # lets pass the vars to bash
        self.edit_param('lang', language)
        self.edit_param('url', url.get_text())
        self.edit_param('api_key', api_key.get_text())
        self.edit_param('device_key', device_key.get_text())
        
        # lets change the crontab interval
    	os.system('(sudo crontab -l | grep -v prey; echo "*/'+str(minutes.get_value_as_int())+' * * * * cd /usr/share/prey; ./prey.sh > /dev/null") | sudo crontab -')
        gtk.main_quit()

       # def change_digits(self, widget, minutes):
       # print "Minutes: %s\n" % minutes.get_value_as_int()

    def edit_param(self, param, value):
        config_file = '/usr/share/prey/config'
        if param == 'url': value = value.replace('/', '\/')
        command = 'sed -i -e "s/'+param+'=\'.*\'/'+param+'=\''+value+'\'/" '+ config_file
        # print command
        os.system(command)

    def __init__(self):
        window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        # window.set_size_request(250, 450)
        window.set_title("Prey Configurator")
        window.set_border_width(1)
        window.set_resizable(False)
        window.connect("delete_event", lambda w,e: gtk.main_quit())

        # main vertical box

        main_vbox = gtk.VBox(False, 5)
        main_vbox.set_border_width(10)
        window.add(main_vbox)

        image = gtk.Image()
        image.set_from_file("/usr/share/prey/pixmaps/prey.png")
        main_vbox.add(image)

        label = gtk.Label("Prey Configurator")
        label.set_alignment(0, 0.5)
        main_vbox.pack_start(label, False, False, 5)

        # first frame

        frame = gtk.Frame("Main settings")
        main_vbox.pack_start(frame, True, True, 0)

        vbox = gtk.VBox(False, 0)
        vbox.set_border_width(5)
        frame.add(vbox)

        # lang field

        label = gtk.Label("Language:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        lang = gtk.combo_box_new_text()
        lang.append_text('en')
        lang.append_text('es')
        lang.append_text('sv')
        lang.set_active(0)
        vbox.pack_start(lang, False, True, 0)

        # url field

        label = gtk.Label("Check URL:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        url = gtk.Entry()
        url.set_max_length(50)
        # url.connect("activate", self.enter_callback, url)
        url.set_text("http://www.mypage.com/stolen_laptop")
        # url.insert_text(" world", len(url.get_text()))
        # url.select_region(0, len(url.get_text()))
        vbox.pack_start(url, False, True, 0)

        # api key field

        label = gtk.Label("API Key:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        api_key = gtk.Entry()
        api_key.set_max_length(12)
        vbox.pack_start(api_key, False, True, 0)
              
        label = gtk.Label("Device Key:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        device_key = gtk.Entry()
        device_key.set_max_length(6)
        vbox.pack_start(device_key, False, True, 0)

        hbox = gtk.HBox(False, 0)
        main_vbox.add(hbox)
        hbox.show()
                               
        check = gtk.CheckButton("Web service")
        hbox.pack_start(check, False, True, 0)
        check.connect("toggled", self.entry_toggle_web_service, url, api_key, device_key)
        check.set_active(True)
    
        # check = gtk.CheckButton("Visible")
        # hbox.pack_start(check, True, True, 0)
        # check.connect("toggled", self.entry_toggle_visibility, entry)
        # check.set_active(True)
        # check.show()

        # second frame

        frame = gtk.Frame("More Settings")
        main_vbox.pack_start(frame, True, True, 0)

        vbox = gtk.VBox(False, 0)
        vbox.set_border_width(5)
        frame.add(vbox)

        # run interval

        label = gtk.Label("Time:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        current_interval = os.popen('crontab -l | grep prey | cut -c 3-4').read()
        if not current_interval: current_interval = 20

        adj = gtk.Adjustment(float(current_interval), 1, 59, 1, 1, 0)
        minutes = gtk.SpinButton(adj, 0.0, 0)
        minutes.set_wrap(True)
        # adj.connect("value_changed", self.change_digits, minutes)
        vbox.pack_start(minutes, False, True, 0)

        # horizontal box and close button
  
        hbox = gtk.HBox(False, 0)
        main_vbox.add(hbox)
        hbox.show()

        button = gtk.Button("Cancel")
        button.connect("clicked", lambda w: gtk.main_quit())
        hbox.pack_start(button, True, True, 0)
                                   
        button = gtk.Button("Accept")
        button.connect("clicked", self.apply_settings, lang, url, api_key, device_key, minutes)
        hbox.pack_start(button, True, True, 0)
        button.set_flags(gtk.CAN_DEFAULT)
        button.grab_default()

        window.show_all()

def main():
    gtk.main()
    return 0

if __name__ == "__main__":
    PreyConfigurator()
    main()

