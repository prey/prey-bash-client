#!/usr/bin/env python

# Prey Installer
# By Tomas Pollak (bootlog.org)

import pygtk
pygtk.require('2.0')
import gtk
import os

class PreyConfigurator:
    def entry_toggle_web_service(self, checkbutton, url, api_key, device_key):
        check_url.set_editable(not checkbutton.get_active())
        api_key.set_editable(checkbutton.get_active())
        device_key.set_editable(checkbutton.get_active())

    def entry_toggle_visibility(self, checkbutton, entry):
        entry.set_visibility(checkbutton.get_active())

    def changed_post_method(self, combobox, notebook, check_url):
        model = combobox.get_model()
        index = combobox.get_active()
        notebook.set_current_page(index)
        check_url.set_editable(index != 0)
        if index == 0:
            check_url.set_text('http://preyproject.com')

    def changed_device_key(self, widget, device_key, check_url):
        check_url.set_text("http://preyproject.com/"+device_key.get_text())
        print "Device Key: %s" % device_key.get_text()

    def get_current_var(self, var):
        command = 'grep \''+var+'=\' /usr/share/prey/config | sed "s/'+var+'=\'\(.*\)\'/\\1/"'
        return os.popen(command).read().strip()

    def get_current_settings(self):
        # TODO: REDUCE LINES OF CODE!!!

        self.current_interval = os.popen('crontab -l | grep prey | cut -c 3-4').read()
        if not self.current_interval: self.current_interval = 20

        self.current_lang = self.get_current_var('lang')
        self.current_check_url = self.get_current_var('check_url')
        self.current_post_method = self.get_current_var('post_method')

        self.current_api_key = self.get_current_var('api_key')
        self.current_device_key = self.get_current_var('device_key')

        self.current_mail_to = self.get_current_var('mail_to')
        self.current_smtp_server = self.get_current_var('smtp_server')
        self.current_smtp_username = self.get_current_var('smtp_username')
        # self.current_smtp_password = self.get_current_var('smtp_password')

        self.current_scp_server = self.get_current_var('scp_server')
        self.current_scp_path = self.get_current_var('scp_path')

    def apply_settings(self, checkbutton, lang, minutes, check_url, post_method, api_key, device_key, mail_to, smtp_server, smtp_username, smtp_password, scp_server, scp_path):

        model = lang.get_model()
        index = lang.get_active()
        l = model[index][0]
        if l == 'English':
            language = 'en'
        elif l == 'Espanol':
            language = 'es'
        elif l == 'Sverige':
            language = 'sv'

        model = post_method.get_model()
        index = post_method.get_active()
        if index == 0:
            real_post_method = 'http'
        elif index == 1:
            real_post_method = 'email'
        elif index == 2:
            real_post_method = 'scp'

        # print "Lang: %s" % language
        # print "Inverval (minutes): %s" % minutes.get_value_as_int()
        # print "Check URL: %s" % check_url.get_text()
        # print "API Key: %s" % api_key.get_text()
        # print "Device Key: %s" % device_key.get_text()

        self.edit_param('lang', language)
        self.edit_param('check_url', check_url.get_text())
        self.edit_param('post_method', real_post_method)

        self.edit_param('api_key', api_key.get_text())
        self.edit_param('device_key', device_key.get_text())

        self.edit_param('mail_to', mail_to.get_text())
        self.edit_param('smtp_server', smtp_server.get_text())
        self.edit_param('smtp_username', smtp_username.get_text())

        if smtp_password.get_text() != '':
            encoded_pass = os.popen('echo -n "'+ smtp_password.get_text() + '" | openssl enc -base64').read().strip()
            self.edit_param('smtp_password', encoded_pass)

        self.edit_param('scp_server', scp_server.get_text())
        self.edit_param('scp_path', scp_path.get_text())

        # lets change the crontab interval
        os.system('(crontab -l | grep -v prey; echo "*/'+str(minutes.get_value_as_int())+' * * * * /usr/share/prey/prey.sh > /dev/null") | crontab -')
        gtk.main_quit()

       # def change_digits(self, widget, minutes):
       # print "Minutes: %s\n" % minutes.get_value_as_int()

    def edit_param(self, param, value):
        config_file = '/usr/share/prey/config'
        if param == 'check_url': value = value.replace('/', '\/')
        command = 'sed -i -e "s/'+param+'=\'.*\'/'+param+'=\''+value+'\'/" '+ config_file
        # print command
        os.system(command)

    def __init__(self):
        # first lets get the current settings to apply them
        self.get_current_settings()

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
        vbox.add(label)

        lang = gtk.combo_box_new_text()
        lang.append_text('English')
        lang.append_text('Espanol')
        lang.append_text('Sverige')
        lang.set_active(0)
        vbox.pack_start(lang, False, True, 0)

        # run interval

        label = gtk.Label("Run interval (in minutes):")
        label.set_alignment(0, 0.5)
        vbox.add(label)

        adj = gtk.Adjustment(float(self.current_interval), 1, 59, 1, 1, 0)
        minutes = gtk.SpinButton(adj, 0.0, 0)
        minutes.set_wrap(True)
        # adj.connect("value_changed", self.change_digits, minutes)
        vbox.pack_start(minutes, False, True, 0)

        # check url

        label = gtk.Label("Check URL:")
        label.set_alignment(0, 0.5)
        vbox.add(label)

        check_url = gtk.Entry()
        check_url.set_max_length(100)

        check_url.set_text(self.current_check_url)
        vbox.pack_start(check_url, False, True, 0)

        # posting method

        label = gtk.Label("Data posting method:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        post_method = gtk.combo_box_new_text()
        post_method.append_text('Web service (Recommended)')
        post_method.append_text('SMTP Email')
        post_method.append_text('Secure Copy (SCP)')

        post_method.set_active(0)
        vbox.pack_start(post_method, False, True, 0)

        # we need to set it up after the post method exists
        check_url.set_editable(post_method.get_active() != 0)

        # second frame

        table = gtk.Table(30,6, False)
        main_vbox.add(table)

        # Create a new notebook, place the position of the tabs
        notebook = gtk.Notebook()
        notebook.set_tab_pos(gtk.POS_TOP)
        notebook.set_show_tabs(False)
        table.attach(notebook, 0,6,0,1)
        self.show_tabs = True
        self.show_border = True

        # http, first tab

        vbox = gtk.VBox(False, 0)
        vbox.set_border_width(5)

#        check = gtk.CheckButton("Web service")
#        hbox.pack_start(check, False, True, 0)
#        check.connect("toggled", self.entry_toggle_web_service, url, api_key, device_key)
#        check.set_active(True)

        # post url field

        # label = gtk.Label("Post URL:")
        # label.set_alignment(0, 0.5)
        # vbox.pack_start(label, False, True, 0)

        # post_url = gtk.Entry()
        # post_url.set_max_length(100)
        # url.connect("activate", self.enter_callback, url)
        # post_url.set_text("http://mypage.com/stolen_laptop")
        # url.insert_text(" world", len(url.get_text()))
        # url.select_region(0, len(url.get_text()))
        # vbox.pack_start(post_url, False, True, 0)

        # api key field

        label = gtk.Label("API Key:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        api_key = gtk.Entry()
        api_key.set_max_length(12)
        api_key.set_text(self.current_api_key)
        vbox.pack_start(api_key, False, True, 0)

        label = gtk.Label("Device Key:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        device_key = gtk.Entry()
        device_key.set_max_length(6)
        device_key.set_text(self.current_device_key)
        device_key.connect("insert-at-cursor", self.changed_device_key, device_key, check_url)
        vbox.pack_start(device_key, False, True, 0)

        label = gtk.Label("Remember to register in \n http://preyproject.com for your\n API and Device keys!")
        label.set_justify(gtk.JUSTIFY_CENTER)
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 10)

        label = gtk.Label('HTTP Settings')
        notebook.append_page(vbox, label)

        # email tab

        vbox = gtk.VBox(False, 0)
        vbox.set_border_width(5)

        label = gtk.Label("Mail to:")
        label.set_alignment(0, 0.5)
        vbox.add(label)

        mail_to = gtk.Entry()
        mail_to.set_text(self.current_mail_to)
        vbox.pack_start(mail_to, False, True, 0)

        label = gtk.Label("SMTP Server:")
        label.set_alignment(0, 0.5)
        vbox.add(label)

        smtp_server = gtk.Entry()
        smtp_server.set_text(self.current_smtp_server)
        vbox.pack_start(smtp_server, False, True, 0)

        label = gtk.Label("Username/mailbox:")
        label.set_alignment(0, 0.5)
        vbox.add(label)

        smtp_username = gtk.Entry()
        smtp_username.set_text(self.current_smtp_username)
        vbox.pack_start(smtp_username, False, True, 0)

        label = gtk.Label("Password:")
        label.set_alignment(0, 0.5)
        vbox.add(label)

        smtp_password = gtk.Entry()
        smtp_password.set_visibility(False)
        # smtp_password.set_text(self.current_smtp_password)
        vbox.pack_start(smtp_password, False, True, 0)

        label = gtk.Label('Email Settings')
        notebook.append_page(vbox, label)

        # scp tab

        vbox = gtk.VBox(False, 0)
        vbox.set_border_width(5)

        label = gtk.Label("SCP Server:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        scp_server = gtk.Entry()
        scp_server.set_text("my.server.com")
        vbox.pack_start(scp_server, False, True, 0)

        label = gtk.Label("SCP Path:")
        label.set_alignment(0, 0.5)
        vbox.pack_start(label, False, True, 0)

        scp_path = gtk.Entry()
        scp_path.set_text("~")
        vbox.pack_start(scp_path, False, True, 0)

        label = gtk.Label('SCP Settings')
        notebook.append_page(vbox, label)

        # end notebook

        notebook.set_current_page(post_method.get_active())
        post_method.connect('changed', self.changed_post_method, notebook, check_url)

        # horizontal box and close button

        hbox = gtk.HBox(False, 0)
        main_vbox.add(hbox)

        button = gtk.Button("Cancel")
        button.connect("clicked", lambda w: gtk.main_quit())
        hbox.pack_start(button, True, True, 0)

        button = gtk.Button("Accept")
        button.connect("clicked", self.apply_settings, lang, minutes, check_url, post_method, api_key, device_key, mail_to, smtp_server, smtp_username, smtp_password, scp_server, scp_path )
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
