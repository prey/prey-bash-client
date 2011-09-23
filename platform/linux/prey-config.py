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
import base64

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
PREY_CONFIG_FILE = PREY_PATH + '/config'
PREY_COMMAND = PREY_PATH + '/prey.sh > /var/log/prey.log 2>&1'
CONTROL_PANEL_URL = 'http://control.preyproject.com'
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
			# NOTE: domain suffix should be one of those in this list: http://en.wikipedia.org/wiki/List_of_Internet_top-level_domains
			if re.match("^.+\\@(\\[?)[a-zA-Z0-9\\-\\.]+\\.([a-zA-Z]{2,4}|[0-9]{1,3}|travel|museum)(\\]?)$", string) != None:
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
		elif self.text('password') != self.text('password_confirm'):
			self.show_alert(_("Passwords don't match"), _("Please make sure both passwords match!"))
			return False
		return True

	################################################
	# dialogs
	################################################

	def show_alert(self, title, message, quit = False):
		dialog = gtk.MessageDialog(
			parent         = None,
			flags          = gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT,
			type           = gtk.MESSAGE_INFO,
			buttons        = gtk.BUTTONS_OK,
			message_format = message)
		dialog.set_title(title)
		if quit == True:
			dialog.connect('response', lambda dialog, response: gtk.main_quit())
		else:
			dialog.connect('response', lambda dialog, response: dialog.destroy())
		self.center_dialog(dialog)
		dialog.show()

	def show_question(self, title, message):
		dialog = gtk.MessageDialog(
			parent         = None,
			flags          = gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT,
			type           = gtk.MESSAGE_QUESTION,
			buttons        = gtk.BUTTONS_YES_NO,
			message_format = message)
		dialog.set_title(title)
		self.center_dialog(dialog)
		response = dialog.run()
		dialog.destroy()
		return response

	def show_about(self):
		dialog = self.get('about_prey_config')
		self.center_dialog(dialog)
		dialog.show()

	def close_about(self, dialog, response):
		dialog.hide()

	def center_dialog(self, dialog):
		if 'window' in self.__dict__:
			dialog.set_transient_for(self.window)
		dialog.set_position(gtk.WIN_POS_CENTER_ON_PARENT)

	################################################
	# window and widget management
	################################################

	def get_page_name(self):
		return PAGES[self.pages.get_current_page()]

	def toggle_pg3_next_apply(self, button):
		button_next = self.get('button_next')
		button_apply = self.get('button_apply')
		if self.get('use_existing_device').get_active() == False:
			button_next.hide()
			button_apply.show()
			button_apply.grab_default()
		else:
			button_apply.hide()
			button_next.show()
			button_next.grab_default()

	def next_page(self, button):
		page_name = self.get_page_name()
		increment = 1

		if page_name == 'control_panel_options' and self.get('new_user_option').get_active() == False:
			increment = 2

		if page_name == 'report_options':
			if self.get('reporting_mode_cp').get_active() == True:
				if self.current_api_key != '':
					response = self.show_question(_("Hold your horses!"), _("Your device seems to be already synchronized with the Control Panel! Do you want to re-setup your account? (Not recommended)"))
					if response == gtk.RESPONSE_NO:
						return
			else:
				increment = 5

		if page_name == 'existing_user': # then we are going to select an exising device
			if not self.get_existing_user(True):
				# login didn't work, so don't go to next page
				return

		self.pages.set_current_page(self.pages.get_current_page() + increment)
		self.toggle_buttons(button, None, 1)

	def prev_page(self, button):
		page_name = self.get_page_name()
		decrement = 1

		if page_name == 'existing_user':
			decrement = 2
		elif page_name == 'standalone_options':
			decrement = 5

		if self.pages.get_current_page() != 0:
			self.pages.set_current_page(self.pages.get_current_page() - decrement)

		self.toggle_buttons(button, None, 1)

	def toggle_buttons(self, button, tab, tab_number):
		button_prev = self.get('button_prev')
		button_next = self.get('button_next')
		button_apply = self.get('button_apply')
		if tab_number == 0: #main settings tab
			button_prev.hide()
			button_next.hide()
			button_apply.show()
			self.hide_ssl()
		else:
			page_name = self.get_page_name()
			if page_name == 'report_options':
				button_prev.hide()
			else:
				button_prev.show()

			if page_name == 'report_options' or page_name == 'control_panel_options' or (page_name == 'existing_user' and self.get('use_existing_device').get_active() == True):
				button_apply.hide()
				button_next.show()
				button_next.grab_default()
			else:
				button_next.hide()
				button_apply.show()
				button_apply.grab_default()

			if self.get_page_name() == 'new_user' or self.get_page_name() == 'existing_user':
				self.show_ssl()
			else:
				self.hide_ssl()

	def hide_ssl(self):
		self.get('icon_ssl').hide()
		self.get('lbl_ssl').hide()

	def show_ssl(self):
		self.get('icon_ssl').show()
		self.get('lbl_ssl').show()

	def set_default_action(self,button,ctrl):
		button_cancel = self.get('button_cancel')
		cancel_has_default = button_cancel.flags() & gtk.HAS_DEFAULT
		button_prev = self.get('button_prev')
		prev_has_default = button_prev.flags() & gtk.HAS_DEFAULT
		button_next = self.get('button_next')
		button_apply = self.get('button_apply')
		if not cancel_has_default and not prev_has_default:
			if button_next.flags() & gtk.VISIBLE:
				button_next.grab_default()
			else:
				button_apply.grab_default()

	def ensure_visible(self,widget,event): # ensure the widget focused is visible in the scroll window
		self.get('delay').set_name('delay')
		self.get('extended_headers').set_name('extended_headers')
		widget_name = widget.get_name()
		scrollwindow = self.get('main_settings_scrollwindow')
		internal_height = self.get('main_settings').get_size()[1]
		port_height = scrollwindow.allocation.height
		port_vadjust = scrollwindow.get_vadjustment()
		port_posn = port_vadjust.value
		widget_posn = widget.allocation.y
		widget_height = widget.allocation.height
		if (widget_posn - port_posn) >= 0 and (widget_posn + widget_height - port_posn) <= port_height:
			#widget is fully visible (even if its description or icon is not), so do nothing
			return False

		# for now we know there are only two possible hidden widgets so we scroll all the way up or all the way down
		# if we add options to this page we will have to scroll differently
		if widget_name == 'delay':
			#scroll to top
			port_vadjust.set_value(0)
		elif widget_name == 'extended_headers':
			#scroll to bottom
			port_vadjust.set_value(internal_height - port_height)

		return True

	def key_pressed(self, widget, event):
		# show about dialog on F1 keypress
		if (event.keyval == gtk.keysyms.F1) \
		and (event.state & gtk.gdk.CONTROL_MASK) == 0 \
		and (event.state & gtk.gdk.SHIFT_MASK) == 0:
			self.show_about()
			return True

		return False

	################################################
	# setting getting
	################################################

	def prey_exists(self):
		if not os.path.exists(PREY_PATH + '/core'):
			self.show_alert(_("Prey not installed"), _("Couldn't find a Prey installation on this system. Sorry."), True)
		else:
			return True

	def is_config_writable(self):
		if not os.access(PREY_CONFIG_FILE, os.W_OK):
			self.show_alert(_("Unauthorized"), _("You don't have access to manage Prey's configuration. Sorry."), True)
		else:
			return True

	def update_delay(self, new_delay):
		return os.system('(crontab -l | grep -v prey; echo "*/' + str(new_delay) + ' * * * * ' + PREY_COMMAND + '") | crontab -')

	def get_delay(self):
		delay = os.popen("crontab -l | grep prey | awk '{print $1}'").read()
		if not delay or delay == '' or delay.rfind('*') == -1:
			return 20
		else:
			return delay.replace('*/', '')

	def get_setting(self, var):
		command = 'grep \''+var+'=\' '+PREY_CONFIG_FILE+' | sed "s/'+var+'=\'\(.*\)\'/\\1/"'
		return os.popen(command).read().strip()

	def get_current_settings(self):

		self.current_delay = self.get_delay()

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
			os.system("useradd -m " + GUEST_ACCOUNT_NAME + "; passwd -d " + GUEST_ACCOUNT_NAME)
			# Authorize login with no passwords in gdm
			os.system("sed -i 's/PasswordRequired=false/#PasswordRequired=false/' /etc/gdm/gdm.conf")
			# Authorize login with no passwords in pam
			os.system("sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth")
		else:
			os.system("userdel -r " + GUEST_ACCOUNT_NAME)
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
			self.get('reporting_mode_standalone').set_active(True)

	def check_if_configured(self):
		if self.current_post_method == 'http' and self.current_api_key == '':
			self.show_alert(_('Welcome!'), _("It seems this is the first time you run this setup. Please set up your reporting method now, otherwise Prey won't work!"))

	################################################
	# setting settings
	################################################

	def save_setting(self, param, value):
		if param == 'check_url': value = value.replace('/', '\/')
		command = 'sed -i -e "s/'+param+'=\'.*\'/'+param+'=\''+value+'\'/" '+ PREY_CONFIG_FILE
		os.system(command)

	def apply_settings(self, button):
		self.get('button_apply').set_label(_("Saving..."))

		if self.get("main_tabs").get_current_page() == 0: # main settings page
			self.apply_main_settings()
		else:
			page_name = self.get_page_name()
			if page_name == 'new_user':
				if self.validate_fields():
					self.create_user()
			elif page_name == "existing_user":	# this is an apply event, so we are creating a new device (no "advanced" device selection)
				self.get_existing_user(False)
			elif page_name == "existing_device":
				self.apply_device_settings()
			elif page_name == "standalone_options":
				self.apply_standalone_settings()

		self.get('button_apply').set_label('gtk-apply')

	def apply_main_settings(self):
		# save('lang', text('lang'))
		self.save_setting('auto_connect', self.checkbox('auto_connect'))
		self.save_setting('extended_headers', self.checkbox('extended_headers'))

		if((self.checkbox('guest_account') == 'y') != self.current_guest_account):
			self.toggle_guest_account(self.checkbox('guest_account') == 'y')

		# check and change the crontab interval
		new_delay = self.get('delay').get_value_as_int()
		if new_delay != int(self.current_delay):
			self.update_delay(new_delay)

		if self.check_if_configured == False:
			self.show_alert(_("All good."), _("Configuration saved. Remember you still need to set up your posting method, otherwise Prey won't work!"))
		else:
			self.show_alert(_("All good."), _("Configuration saved!"), True)

	def apply_control_panel_settings(self):

		if self.current_post_method != 'http':
			self.save_setting('post_method', 'http')

		if self.current_check_url != CONTROL_PANEL_URL:
			self.save_setting('check_url', CONTROL_PANEL_URL)

		# we could eventually use the email as a checking method to remove prey
		# i.e. "under which email was this account set up?"
		self.save_setting('mail_to', self.email)
		self.save_setting('api_key', self.api_key)

		if self.device_key != "":
			self.save_setting('device_key', self.device_key)

	def apply_standalone_settings(self):

		if self.current_post_method != 'email':
			self.save_setting('post_method', 'email')

		self.save_setting('check_url', self.text('check_url'))
		self.save_setting('mail_to', self.text('mail_to'))
		self.save_setting('smtp_server', self.text('smtp_server'))
		self.save_setting('smtp_username', self.text('smtp_username'))

		smtp_password = self.text('smtp_password')

		if smtp_password != '':
			encoded_pass = base64.b64encode(smtp_password)
			self.save_setting('smtp_password', encoded_pass)

		self.exit_configurator()

	def exit_configurator(self):
		self.run_prey()
		self.show_alert(_("Success"), _("Configuration saved! Your device is now setup and being tracked by Prey. Happy hunting!"), True)

	def run_prey(self):
		os.system(PREY_COMMAND + ' &')

	################################################
	# control panel api
	################################################

	def report_connection_issue(self, result):
		print("Connection error. Response from server: " + result)
		self.show_alert(_("Problem connecting"), _("We seem to be having a problem connecting to the Prey Control Panel. This is likely a temporary issue. Please try again in a few moments."))

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
		hostname = os.popen("hostname").read().strip()
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
			if key == self.current_device_key:	#set the choice because we have a matching device key
				chosen = index
			elif title.lower() == hostname.lower and chosen < 0:	#set the choice because we likely have a matching title (but device key takes precedence)
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
		params = urllib.urlencode({'user[name]': self.text('user_name'), 'user[email]': self.email, 'user[password]': self.text('password'), 'user[password_confirmation]' : self.text('password_confirm')})
		# params = 'user[name]='+self.text('user_name')+'&user[email]='+self.email+'&user[password]='+self.text('password')+'&user[password_confirmation]='+self.text('password_confirm')
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
		self.save_setting('device_key', '') # make sure no device key is set in the config file, so Prey calls self_setup
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
			self.report_connection_issue(result)
			return False

		has_available_slots = self.user_has_available_slots(result)
		if not has_available_slots and not show_devices:
			self.show_alert(_("Not allowed"),  _("It seems you've reached your limit for devices!\n\nIf you had previously added this PC, you should select the \"Device already exists\" option to select the device from a list of the ones you have already created.\n\nIf this is a new device, you can also upgrade to a Pro Account to increase your slot count and get access to additional features. For more information, please check\nhttp://preyproject.com/plans."))
			return False

		if show_devices:
			result = os.popen('curl -i -s -k --connect-timeout 5 '+ CONTROL_PANEL_URL_SSL + '/devices.xml -u '+self.email+":'"+password+"'").read().strip()
			if result.find("<key>") != -1:
				return self.get_device_keys(result, has_available_slots)
			else:
				self.report_connection_issue(result)
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
			"toggle_pg3_next_apply" : self.toggle_pg3_next_apply,
			"set_default_action" : self.set_default_action,
			"ensure_visible" : self.ensure_visible,
			"key_pressed" : self.key_pressed,
			"close_about" : self.close_about
		})
		self.window = builder.get_object("window")
		self.window.set_title(self.window.get_title() + " (v" + VERSION + ")")
		# self.window.get_settings().set_string_property('gtk-font-name', 'sans normal 11','');
		self.pages = builder.get_object("reporting_mode_tabs")
		self.root = builder

		self.get('delay').grab_focus()
		about = self.get('about_prey_config')
		about.set_version(VERSION)
		self.display_real_settings()
		self.check_if_configured()

if __name__ == "__main__":
	app = PreyConfigurator()
	gtk.main()
