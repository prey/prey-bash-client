#!/usr/bin/env python

################################################
# Prey Configurator for Linux
# By Tomas Pollak
# (c) 2010 - Fork Ltd. (usefork.com)
################################################

# if having trouble with the GTK theme as root, do this:
# sudo ln -s ~/.themes/ /root/.themes

################################################
# base includes
################################################

import pygtk
pygtk.require("2.0")
import gtk
import os
# from xml.dom.minidom import parseString
import re
import urllib

app_name = 'prey-config'
lang_path = 'lang'
script_path = os.sys.path[0]

################################################
# gettext localization
################################################

import locale
import gettext
# locale.setlocale(locale.LC_ALL, '')
# locale.bindtextdomain(app_name, lang_path)
gettext.bindtextdomain(app_name, lang_path)
gettext.textdomain(app_name)
_ = gettext.gettext

################################################
# vars and such
################################################

PREY_PATH = '/usr/share/prey'
CONFIG_FILE = PREY_PATH + '/config'
CONTROL_PANEL_URL_SSL = 'https://control.preyproject.com'
GUEST_ACCOUNT_NAME = 'guest_account'
VERSION = os.popen("cat " + PREY_PATH + "/version 2> /dev/null").read().strip().replace('version=', '').replace("'",'')

PAGES = ['report_options', 'control_panel_options', 'new_user', 'existing_user', 'existing_device', 'standalone_options']

class PreyConfigurator(object):

	################################################
	# helper functions
	################################################

	def get(self, name):
		return self.root.get_object(name)

	def text(self, name):
		return self.get(name).get_text()

	def checkbox(self, name):
		if self.get(name).get_active() == True:
			return 'y'
		else:
			return 'n'

	################################################
	# validations
	################################################

	def validate_email(self, string):
		if len(string) > 7:
			if re.match("^.+\\@(\\[?)[a-zA-Z0-9\\-\\.]+\\.([a-zA-Z]{2,3}|[0-9]{1,3})(\\]?)$", string) != None:
				return True
		return False

	def validate_fields(self):
		if self.text('user_name') == '':
			self.show_alert(_("Empty name!"), _("Please type in your name."))
			return False
		if self.validate_email(self.text('email')) == False:
			self.show_alert(_("Invalid email"), _("Please make sure the email address you typed is valid."))
			return False
		if len(self.text('password')) < 6:
			self.show_alert(_("Bad password"), _("Password should contain at least 6 chars. Please try again."))
			return False
		elif self.text('password') != self.text('password_two'):
			self.show_alert(_("Passwords don't match"), _("Please make sure both passwords match!"))
			return False
		return True

	################################################
	# dialogs
	################################################

	def show_alert(self, title, message, quit = False):
		dialog = gtk.MessageDialog(
			parent         = None,
			flags          = gtk.DIALOG_DESTROY_WITH_PARENT,
			type           = gtk.MESSAGE_INFO,
			buttons        = gtk.BUTTONS_OK,
			message_format = message)
		dialog.set_title(title)
		if quit == True:
			dialog.connect('response', lambda dialog, response: gtk.main_quit())
		else:
			dialog.connect('response', lambda dialog, response: dialog.destroy())

		dialog.show()

	def show_question(self, title, message):
		dialog = gtk.MessageDialog(
			parent         = None,
			flags          = gtk.DIALOG_DESTROY_WITH_PARENT,
			type           = gtk.MESSAGE_INFO,
			buttons        = gtk.BUTTONS_YES_NO,
			message_format = message)
		dialog.set_title(title)
		return dialog

	################################################
	# window and widget management
	################################################

	def get_page_name(self):
		return PAGES[self.tabs.get_current_page()]
		
	def toggle_pg3_next_apply(self, button):
		if self.get('use_existing_device').get_active() == False:
			self.get('button_next').hide()
			self.get('button_apply').show()
		else:
			self.get('button_apply').hide()
			self.get('button_next').show()

	def next_page(self, button):
		page_name = self.get_page_name()
		increment = 1

		if page_name == 'control_panel_options' and self.get('new_user_option').get_active() == False:
			increment = 2

		if page_name == 'report_options':
			if self.get('reporting_mode_cp').get_active() == True:
				if self.current_api_key != '':
					dialog = self.show_question(_("Hold your horses!"), _("Your device seems to be already synchronized with the Control Panel! Do you want to re-setup your account? (Not recommended)"))
					response = dialog.run()
					dialog.destroy()
					if response == gtk.RESPONSE_NO:
						return
			else:
				increment = 4
		
		if page_name == 'existing_user': # then we are going to select an exising device
			if not self.get_existing_user(True): return

		self.tabs.set_current_page(self.tabs.get_current_page()+increment)
		self.get('button_prev').show()

		if self.tabs.get_current_page() > 1 and (self.tabs.get_current_page() != 3 or self.get('use_existing_device').get_active() == False):
			self.get('button_next').hide()
			self.get('button_apply').show()

		self.show_ssl()

	def prev_page(self, button):
		page_name = self.get_page_name()
		decrement = 1

		if page_name == 'existing_user':
			decrement = 2
		elif page_name == 'standalone_options':
			decrement = 4

		if self.tabs.get_current_page() != 0:
			self.tabs.set_current_page(self.tabs.get_current_page()-decrement)

		if self.tabs.get_current_page() == 0:
			self.get('button_prev').hide()

		if self.tabs.get_current_page() < 2 or (self.tabs.get_current_page() == 3 and self.get('use_existing_device').get_active() == True):
			self.get('button_apply').hide()
			self.get('button_next').show()

		self.hide_ssl()

	def toggle_buttons(self, button, pointer, page_number):
		button_prev = self.get('button_prev')
		button_next = self.get('button_next')
		button_apply = self.get('button_apply')
		if button_next.flags() & gtk.VISIBLE:
			button_prev.hide()
			button_next.hide()
			button_apply.show()
			self.show_ssl()
		else:
			button_next.show()
			button_apply.hide()
			self.hide_ssl()
			if self.tabs.get_current_page() > 0:
				button_prev.show()

	def hide_ssl(self):
		self.get('ssl_icon').hide()
		self.get('ssl_text').hide()

	def show_ssl(self):
		if self.get_page_name() == 'new_user' or self.get_page_name() == 'existing_user':
			self.get('ssl_icon').show()
			self.get('ssl_text').show()

	################################################
	# setting getting
	################################################

	def prey_exists(self):
		if not os.path.exists(PREY_PATH + '/core'):
			self.show_alert(_("Prey not installed"), _("Couldn't find a Prey installation on this system. Sorry."), True)
		else:
			return True

	def is_config_writable(self):
		command = 'if [ ! -w "'+PREY_PATH+'/config" ]; then echo 1; fi'
		no_access = os.popen(command).read().strip()
		if no_access == '1':
			self.show_alert(_("Unauthorized"), _("You don't have access to manage Prey's configuration. Sorry."), True)
		else:
			return True

	def get_setting(self, var):
		command = 'grep \''+var+'=\' '+CONFIG_FILE+' | sed "s/'+var+'=\'\(.*\)\'/\\1/"'
		return os.popen(command).read().strip()

	def get_current_settings(self):

		self.current_delay = os.popen("crontab -l | grep prey | cut -c 3-4").read()
		if not self.current_delay: self.current_delay = 20

		self.current_auto_connect = self.get_setting('auto_connect')
		self.current_extended_headers = self.get_setting('extended_headers')
		self.current_guest_account = self.guest_account_exists()

		self.current_lang = self.get_setting('lang')
		self.current_check_url = self.get_setting('check_url')
		self.current_post_method = self.get_setting('post_method')

		self.current_api_key = self.get_setting('api_key')
		self.current_device_key = self.get_setting('device_key')

		self.current_mail_to = self.get_setting('mail_to')
		self.current_smtp_server = self.get_setting('smtp_server')
		self.current_smtp_username = self.get_setting('smtp_username')

	def guest_account_exists(self):
		result = os.popen('id ' + GUEST_ACCOUNT_NAME + ' 2> /dev/null').read()
		if result.find("uid"):
			return False
		else:
			return True

	def toggle_guest_account(self, enabled):
		if enabled:
			# create user and leave password blank
			os.system("useradd " + GUEST_ACCOUNT_NAME + "; passwd -d " + GUEST_ACCOUNT_NAME)
			# Authorize login with no passwords in gdm
			os.system("sed -i 's/PasswordRequired=false/#PasswordRequired=false/' /etc/gdm/gdm.conf")
			# Authorize login with no passwords in pam
			os.system("sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth")
		else:
			os.system("userdel " + GUEST_ACCOUNT_NAME)
			os.system("sed -i 's/#PasswordRequired=false/PasswordRequired=false/' /etc/gdm/gdm.conf")
			os.system("sed -i 's/nullok/nullok_secure/' /etc/pam.d/common-auth")

	def display_real_settings(self):
		self.get('delay').set_value(int(self.current_delay))
		self.get('guest_account').set_active(self.current_guest_account)

		if self.current_auto_connect == 'y':
			self.get('auto_connect').set_active(True)

		if self.current_extended_headers == 'y':
			self.get('extended_headers').set_active(True)

		self.get('check_url').set_text(self.current_check_url)
		self.get('mail_to').set_text(self.current_mail_to)
		self.get('smtp_server').set_text(self.current_smtp_server)
		self.get('smtp_username').set_text(self.current_smtp_username)

		if self.current_post_method == 'email':
			self.get('reporting_mode_email').set_active(True)

	def check_if_configured(self):
		if self.current_post_method == 'http' and self.current_api_key == '':
			self.show_alert(_('Welcome!'), _("It seems this is the first time you run this setup. Please set up your reporting method now, otherwise Prey won't work!"))

	################################################
	# setting settings
	################################################

	def save(self, param, value):
		if param == 'check_url': value = value.replace('/', '\/')
		command = 'sed -i -e "s/'+param+'=\'.*\'/'+param+'=\''+value+'\'/" '+ CONFIG_FILE
		os.system(command)

	def apply_settings(self, button):
		self.get('button_apply').set_label('Saving...')

		if self.get("main_tabs").get_current_page() == 0: # main settings page
			self.apply_main_settings()
		else:
			page_name = self.get_page_name()
			if page_name == 'new_user':
				if self.validate_fields():
					self.create_user()
			elif page_name == "existing_user":
				self.get_existing_user(False)
			elif page_name == "existing_device":
				self.apply_device_settings()
			elif page_name == "standalone_options":
				self.apply_standalone_settings()

		self.get('button_apply').set_label('Apply')

	def apply_main_settings(self):
		# save('lang', text('lang'))
		self.save('auto_connect', self.checkbox('auto_connect'))
		self.save('extended_headers', self.checkbox('extended_headers'))

		if((self.checkbox('guest_account') == 'y') != self.current_guest_account):
			self.toggle_guest_account(self.checkbox('guest_account') == 'y')

		# check and change the crontab interval
		new_delay = self.get('delay').get_value_as_int()
		if new_delay != int(self.current_delay):
			# print 'Updating delay in crontab...'
			os.system('(crontab -l | grep -v prey; echo "*/'+str(new_delay)+' * * * * /usr/share/prey/prey.sh > /var/log/prey.log") | crontab -')

		if self.check_if_configured == False:
			self.show_alert(_("All good."), _("Configuration saved. Remember you still need to set up your posting method, otherwise Prey won't work!"))
		else:
			self.show_alert(_("All good."), _("Configuration saved!"), True)

	def apply_control_panel_settings(self):

		if self.current_post_method != 'http':
			self.save('post_method', 'http')

		# we could eventually use the email as a checking method to remove prey
		# i.e. "under which email was this account set up?"
		# self.save('mail_to', self.email)
		self.save('api_key', self.api_key)
		self.save('device_key', self.device_key)

	def apply_standalone_settings(self):

		if self.current_post_method != 'email':
			self.save('post_method', 'email')

		self.save('check_url', self.text('check_url'))
		self.save('mail_to', self.text('mail_to'))
		self.save('smtp_server', self.text('smtp_server'))
		self.save('smtp_username', self.text('smtp_username'))

		smtp_password = self.text('smtp_password')

		if smtp_password != '':
			encoded_pass = os.popen('echo -n "'+ smtp_password + '" | openssl enc -base64').read().strip()
			self.save('smtp_password', encoded_pass)

		self.exit_configurator()

	def exit_configurator(self):
		self.run_prey()
		self.show_alert(_("You can now rest assured."), _("Configuration saved! Your device is now setup and being tracked by Prey. Happy hunting!"), True)

	def run_prey(self):
		os.system(PREY_PATH + '/prey.sh > /var/log/prey.log')

	################################################
	# control panel api
	################################################

	def report_connection_issue(self):
		self.show_alert(_("Problem connecting"), _("We seem to be having a problem connecting to your Control Panel. This is likely a temporary issue. Please try again in a few moments."))

	def user_has_available_slots(self, string):
		matches = re.search(r"<available_slots>(\w*)</available_slots>", string)
		if matches and int(matches.groups()[0]) > 0:
			return True
		else:
			return False

	def get_api_key(self, string):
		matches = re.search(r"<key>(\w*)</key>", string)
		if matches:
			self.api_key = matches.groups()[0]

	def get_device_keys(self, string, has_available_slots):
		devices = self.get('device')
		index = -1
		chosen = index
		liststore = gtk.ListStore(str,str)
		devices.clear()
		matches = re.findall(r"<device>\s*<key>(\w*)</key>.*?<title>([\s\w]*)</title>\s*</device>", string, re.DOTALL)
		for match in matches:
			index += 1
			key = match[0]
			title = match[1]
			liststore.append([title,key])
			if key == self.current_device_key:
				chosen = index
		if index < 0:
			#self.get('create_new_device').set_active(True)
			self.show_alert(_("No devices exist"), _("There are no devices currently defined in your Control Panel.\n\nPlease select the option to create a new device."))
			return False

		devices.set_model(liststore)
		cell = gtk.CellRendererText()
		devices.pack_start(cell, True)
		devices.add_attribute(cell, 'text', 0)
		devices.set_active(chosen)
		return True

	def create_user(self):
		self.email = self.text('email')
		params = urllib.urlencode({'user[name]': self.text('user_name'), 'user[email]': self.email, 'user[password]': self.text('password'), 'user[password_confirmation]' : self.text('password_two')})
		# params = 'user[name]='+self.text('user_name')+'&user[email]='+self.email+'&user[password]='+self.text('password')+'&user[password_confirmation]='+self.text('password_two')
		result = os.popen('curl -i -s -k --connect-timeout 5 '+ CONTROL_PANEL_URL_SSL + '/users.xml -d \"'+params+'\"').read().strip()

		if result.find("<key>") != -1:
			self.get_api_key(result)
			self.device_key = ""
		elif result.find("Email has already been taken") != -1:
			self.show_alert(_("Email has already been taken"), _("That email address already exists! If you signed up previously, please go back and select the Existing User option."))
			return
		else:
			self.show_alert(_("Couldn't create user!"), _("There was a problem creating your account. Please make sure the email address you entered is valid, as well as your password."))
			return
			
		self.apply_control_panel_settings()
		self.run_prey()
		self.show_alert(_("Account created!"), _("Your account has been succesfully created and configured in Prey's Control Panel.\n\nPlease check your inbox now, you should have received a verification email."), True)

	def get_existing_user(self, show_devices):
		self.email = self.text('existing_email')
		password = self.text('existing_password')
		result = os.popen('curl -i -s -k --connect-timeout 5 '+ CONTROL_PANEL_URL_SSL + '/profile.xml -u '+self.email+":'"+password+"'").read().strip()

		if result.find('401 Unauthorized') != -1:
			self.show_alert(_("User does not exist"), _("Couldn't log you in. Remember you need to activate your account opening the link we emailed you.\n\nIf you forgot your password please visit preyproject.com."))
			return

		if result.find("<user>") != -1:
			self.get_api_key(result)
		else:
			self.report_connection_issue()
			return False
			
		has_available_slots = self.user_has_available_slots(result)
		if not has_available_slots and not show_devices:
			self.show_alert(_("Not allowed"),  _("It seems you've reached your limit for devices!\n\nIf you had previously added this PC, you should select the \"Device already exists\" option to select the device from a list of devices you have already defined.\n\nIf this is a new device, you can also upgrade to a Pro Account to increase your slot count and get access to additional features. For more information, please check\nhttp://preyproject.com/plans."))
			return False

		if show_devices:
			result = os.popen('curl -i -s -k --connect-timeout 5 '+ CONTROL_PANEL_URL_SSL + '/devices.xml -u '+self.email+":'"+password+"'").read().strip()
			if result.find("</devices>") != -1:
				return self.get_device_keys(result,has_available_slots)
			else:
				self.report_connection_issue()
				return False
		else:
			self.device_key = ""
			self.apply_control_panel_settings()
			self.exit_configurator()

	def apply_device_settings(self):
		devices = self.get('device')
		model = devices.get_model()
		self.device_key = model.get_value(devices.get_active_iter(),1)
		self.apply_control_panel_settings()
		self.exit_configurator()

	def __init__(self):

		if not self.prey_exists() or not self.is_config_writable():
			gtk.main()
			exit(1)

		self.get_current_settings()

		builder = gtk.Builder()
		builder.set_translation_domain(app_name)
		builder.add_from_file(script_path + "/prey-config.glade")
		builder.connect_signals({
			"on_window_destroy" : gtk.main_quit,
			"prev_page" : self.prev_page,
			"next_page" : self.next_page,
			"toggle_buttons" : self.toggle_buttons,
			"apply_settings" : self.apply_settings,
			"toggle_pg3_next_apply" : self.toggle_pg3_next_apply
		})
		self.window = builder.get_object("window")
		self.window.set_title(self.window.get_title() + " (v" + VERSION + ")")
		# self.window.get_settings().set_string_property('gtk-font-name', 'sans normal 11','');
		self.tabs = builder.get_object("reporting_mode_tabs")
		self.root = builder

		self.display_real_settings()
		self.check_if_configured()

if __name__ == "__main__":
	app = PreyConfigurator()
	gtk.main()
