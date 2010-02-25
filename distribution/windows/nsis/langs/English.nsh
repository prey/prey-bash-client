; -----------------------------------------------------------
; general

LangString CAPTION ${LANG_ENGLISH} "Prey Configurator"
LangString SUBCAPTION ${LANG_ENGLISH} "Settings for Prey"

LangString BRANDING_TEXT ${LANG_ENGLISH} "Prey Configurator"
LangString HEADER_TEXT ${LANG_ENGLISH} "Kick-ass open source device tracking solution. That's right."

LangString ABORT_WARNING ${LANG_ENGLISH} "Are you sure you want to quit? Settings will not be saved."

; -----------------------------------------------------------
; pages

LangString WELCOME_DESC ${LANG_ENGLISH} "Welcome to the Prey Configurator! Please choose your destiny."

LangString SETUP_REPORTS_OPTION ${LANG_ENGLISH} "Setup reporting method"
LangString SETUP_REPORTS_SUMMARY ${LANG_ENGLISH} "Define the way that Prey will communicate and send the report to you."

LangString CHANGE_SETTINGS_OPTION ${LANG_ENGLISH} "Manage Prey settings"
LangString CHANGE_SETTINGS_SUMMARY ${LANG_ENGLISH} "Change the running delay or activate specific features."

; -----------------------------------------------------------
; settings page

LangString CHANGE_SETTINGS_TITLE ${LANG_ENGLISH} "Prey settings configuration"
LangString CHANGE_SETTINGS_DESC ${LANG_ENGLISH} "These are the basic settings for Prey to work. Module configuration is done via the Control Panel."

LangString SETTING_DELAY_TITLE ${LANG_ENGLISH} "Delay between executions"
LangString SETTING_DELAY_DESC ${LANG_ENGLISH} "Number of minutes to wait before waking up Prey. Control Panel users can change this setting later on the web."

LangString SETTING_GUEST_TITLE ${LANG_ENGLISH} "Enable guest account"
LangString SETTING_GUEST_DESC ${LANG_ENGLISH} "Whether we should allow guest logins on the system. On password-protected computers, this greatly increases the chances of gathering information."

LangString SETTING_WIFI_TITLE ${LANG_ENGLISH} "Wifi autoconnect"

LangString SETTING_WIFI_DESC ${LANG_ENGLISH} "Allow your computer to connect automatically to the nearest available wifi access point, if no connection is found."

; -----------------------------------------------------------
; report page

LangString SETUP_REPORTS_TITLE ${LANG_ENGLISH} "Reporting method setup"
LangString SETUP_REPORTS_DESC ${LANG_ENGLISH} "Please choose the reporting method for Prey. The activation will depend on the method you choose."

LangString CONTROL_PANEL_OPTION ${LANG_ENGLISH} "Prey + Control Panel"
LangString CONTROL_PANEL_SUMMARY ${LANG_ENGLISH} "Recommended option. You manage your device and gather the reports easily on Prey's Control Panel."

LangString CONTROL_PANEL_DESC ${LANG_ENGLISH} "Good choice! Have you already registered in the Control Panel?"

; -----------------------------------------------------------
; control panel pages

LangString CONTROL_PANEL_NEW_USER_OPTION ${LANG_ENGLISH} "Not yet (new user)"
LangString CONTROL_PANEL_NEW_USER_SUMMARY ${LANG_ENGLISH} "Select this if this is the first time you installed Prey, or if you still haven't created an account."

LangString CONTROL_PANEL_NEW_USER_DESC ${LANG_ENGLISH} "Please provide the following information so we can create your account. Once it's created we'll send you an email to confirm the address you entered is correct."

LangString CONTROL_PANEL_EXISTING_USER_TITLE ${LANG_ENGLISH} "Been there, done that (existing user)"
LangString CONTROL_PANEL_EXISTING_USER_SUMMARY ${LANG_ENGLISH} "You already have a Control Panel account and with to associate this device to that account."

LangString CONTROL_PANEL_EXISTING_USER_DESC ${LANG_ENGLISH} "Please type in your login credentials. This information is never stored, and only used for adding your device your Control Panel account."

LangString CONTROL_PANEL_ACCOUNT_SETTINGS ${LANG_ENGLISH} "Account settings"
LangString CONTROL_PANEL_USER_NAME ${LANG_ENGLISH} "Your name"
LangString CONTROL_PANEL_USER_EMAIL ${LANG_ENGLISH} "Email address"
LangString CONTROL_PANEL_USER_PASSWORD ${LANG_ENGLISH} "Password"
LangString CONTROL_PANEL_USER__PASSWORD_TWO ${LANG_ENGLISH} "Confirm password"

LangString CONTROL_PANEL_DEVICE_SETTINGS ${LANG_ENGLISH} "Device settings"
LangString DEVICE_TITLE ${LANG_ENGLISH} "Device title"
LangString DEVICE_TYPE ${LANG_ENGLISH} "Device type"

; -----------------------------------------------------------
; standalone page

LangString STANDALONE_OPTION ${LANG_ENGLISH} "Prey Standalone"
LangString STANDALONE_SUMMARY ${LANG_ENGLISH} "For advanced users. Report goes directly to your inbox, but you need to set up your mail server configuration."

LangString STANDALONE_DESC ${LANG_ENGLISH} "Please configure your SMTP settings."

LangString STANDALONE_CHECK_URL ${LANG_ENGLISH} "URL for check (You'll need to create it later to activate Prey)"
LangString STANDALONE_MAIL_TO ${LANG_ENGLISH} "Mail to"

LangString STANDALONE_SMTP_SERVER ${LANG_ENGLISH} "STMP Server"
LangString STANDALONE_SMTP_USERNAME ${LANG_ENGLISH} "STMP Username"
LangString STANDALONE_SMTP_PASSWORD ${LANG_ENGLISH} "STMP Password"

; -----------------------------------------------------------
; messages

LangString FIRST_TIME_MESSAGE ${LANG_ENGLISH} "It seems this is the first time you run this setup. Please set up your reporting method before configuring Prey's settings."
LangString NOT_ADMIN_MESSAGE ${LANG_ENGLISH} "You must be logged in as an administrator user to manage Prey's configuration."

LangString CONTROL_PANEL_CONFIGURED_MESSAGE ${LANG_ENGLISH} "Your device is already synchronized with the Control Panel! Do you want to re-run the setup? (Not recommended)"
LangString EMAIL_EXISTS_MESSAGE ${LANG_ENGLISH} "The email address you entered already exists! Are you sure you haven't registered yet?"
LangString INVALID_PARAMS_MESSAGE ${LANG_ENGLISH} "There was a problem creating your account. Please make sure the email address you entered is valid, as well as your password."
LangString ACCOUNT_CREATED_MESSAGE ${LANG_ENGLISH} "Account created! Remember to verify your account by opening your inbox and clicking on the link we sent to your email address."
LangString UNAUTHORIZED_MESSAGE ${LANG_ENGLISH} "Couldn't log you in. Remember you need to activate your account by clicking on the link we sent to your email."
LangString PROBLEM_ADDING_DEVICE_MESSAGE ${LANG_ENGLISH} "There was a problem adding your new device. Maybe you already filled in all your slots for devices?"
LangString SETTINGS_UPDATED_MESSAGE ${LANG_ENGLISH} "Settings successfully updated!"

LangString CONFIGURATION_OK_MESSAGE ${LANG_ENGLISH} "Configuration updated! Your device is now setup and being tracked by Prey. $\r$\nHappy hunting!"

LangString GUEST_ACCOUNT_ADDED_MESSAGE ${LANG_ENGLISH} "Guest account ${GUEST_ACCOUNT_NAME} added succesfully."
LangString GUEST_ACCOUNT_REMOVED_MESSAGE ${LANG_ENGLISH} "Guest account ${GUEST_ACCOUNT_NAME} removed succesfully."


; -----------------------------------------------------------
; buttons

LangString BACK_BUTTON ${LANG_ENGLISH} "< Back"
LangString NEXT_BUTTON ${LANG_ENGLISH} "Next >"
LangString CANCEL_BUTTON ${LANG_ENGLISH} "Cancel"
LangString APPLY_BUTTON ${LANG_ENGLISH} "Apply"
LangString CREATE_BUTTON ${LANG_ENGLISH} "Create"
LangString CREATING_BUTTON ${LANG_ENGLISH} "Creating"
LangString ADD_DEVICE_BUTTON ${LANG_ENGLISH} "Add device"
LangString CONNECTING_BUTTON ${LANG_ENGLISH} "Connecting"
LangString ASSOCIATING_BUTTON ${LANG_ENGLISH} "Associating"
