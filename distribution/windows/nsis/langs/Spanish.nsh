; -----------------------------------------------------------
; general

LangString CAPTION ${LANG_SPANISH} "Configurador Prey"
LangString SUBCAPTION ${LANG_SPANISH} "Parámetros de Prey"

LangString BRANDING_TEXT ${LANG_SPANISH} "Configurador Prey"
LangString HEADER_TEXT ${LANG_SPANISH} "Pueden correr pero no esconderse. Recupera tu computador."

LangString ABORT_WARNING ${LANG_SPANISH} "Estás seguro que quieres salir? La configuración no se guardará."

; -----------------------------------------------------------
; pages

LangString WELCOME_DESC ${LANG_SPANISH} "Bienvenido al configurador de Prey. Elige tu destino."

LangString SETUP_REPORTS_OPTION ${LANG_SPANISH} "Definir método de reportes"
LangString SETUP_REPORTS_SUMMARY ${LANG_SPANISH} "Elige la manera en que Prey se comunicará y te enviará los reportes."

LangString CHANGE_SETTINGS_OPTION ${LANG_SPANISH} "Administrar configuración de Prey"
LangString CHANGE_SETTINGS_SUMMARY ${LANG_SPANISH} "Cambiar la frecuencia de ejecución o activar funciones específicas."

; -----------------------------------------------------------
; settings page

LangString CHANGE_SETTINGS_TITLE ${LANG_SPANISH} "Prey settings configuration"
LangString CHANGE_SETTINGS_DESC ${LANG_SPANISH} "These are the basic settings for Prey to work. Module configuration is done via the Control Panel."

LangString SETTING_DELAY_TITLE ${LANG_SPANISH} "Delay between executions"
LangString SETTING_DELAY_DESC ${LANG_SPANISH} "Number of minutes to wait before waking up Prey. Control Panel users can change this setting later on the web."

LangString SETTING_GUEST_TITLE ${LANG_SPANISH} "Enable guest account"
LangString SETTING_GUEST_DESC ${LANG_SPANISH} "Whether we should allow guest logins on the system. On password-protected computers, this greatly increases the chances of gathering information."

LangString SETTING_WIFI_TITLE ${LANG_SPANISH} "Wifi autoconnect"

LangString SETTING_WIFI_DESC ${LANG_SPANISH} "Allow your computer to connect automatically to the nearest available wifi access point, if no connection is found."

; -----------------------------------------------------------
; report page

LangString SETUP_REPORTS_TITLE ${LANG_SPANISH} "Configuración de reportes"
LangString SETUP_REPORTS_DESC ${LANG_SPANISH} "Elige una de las opciones a continuación. El método de activación de Prey dependerá de la opción que elijas."

LangString CONTROL_PANEL_OPTION ${LANG_SPANISH} "Prey + Panel de Control"
LangString CONTROL_PANEL_SUMMARY ${LANG_SPANISH} "Opción recomendada. Manejas tu computador y recibes los reportes de manera fácil en el Panel de Control de Prey."

LangString CONTROL_PANEL_DESC ${LANG_SPANISH} "Good choice! Have you already registered in the Control Panel?"

; -----------------------------------------------------------
; control panel pages

LangString CONTROL_PANEL_NEW_USER_OPTION ${LANG_SPANISH} "Not yet (new user)"
LangString CONTROL_PANEL_NEW_USER_SUMMARY ${LANG_SPANISH} "Select this if this is the first time you installed Prey, or if you still haven't created an account."

LangString CONTROL_PANEL_NEW_USER_DESC ${LANG_SPANISH} "Please provide the following information so we can create your account. Once it's created we'll send you an email to confirm the address you entered is correct."

LangString CONTROL_PANEL_EXISTING_USER_TITLE ${LANG_SPANISH} "Been there, done that (existing user)"
LangString CONTROL_PANEL_EXISTING_USER_SUMMARY ${LANG_SPANISH} "You already have a Control Panel account and with to associate this device to that account."

LangString CONTROL_PANEL_EXISTING_USER_DESC ${LANG_SPANISH} "Please type in your login credentials. This information is never stored, and only used for adding your device your Control Panel account."

LangString CONTROL_PANEL_ACCOUNT_SETTINGS ${LANG_SPANISH} "Account settings"
LangString CONTROL_PANEL_USER_NAME ${LANG_SPANISH} "Your name"
LangString CONTROL_PANEL_USER_EMAIL ${LANG_SPANISH} "Email address"
LangString CONTROL_PANEL_USER_PASSWORD ${LANG_SPANISH} "Password"
LangString CONTROL_PANEL_USER__PASSWORD_TWO ${LANG_SPANISH} "Confirm password"

LangString CONTROL_PANEL_DEVICE_SETTINGS ${LANG_SPANISH} "Device settings"
LangString DEVICE_TITLE ${LANG_SPANISH} "Device title"
LangString DEVICE_TYPE ${LANG_SPANISH} "Device type"

; -----------------------------------------------------------
; standalone page

LangString STANDALONE_OPTION ${LANG_SPANISH} "Prey independiente"
LangString STANDALONE_SUMMARY ${LANG_SPANISH} "Para usuarios avanzados. El reporte llega directamente a tu casilla, pero debes ingresar tu servidor de correo y realizar la activación de Prey por tú cuenta."

LangString STANDALONE_DESC ${LANG_SPANISH} "Please configure your SMTP settings."

LangString STANDALONE_CHECK_URL ${LANG_SPANISH} "URL for check (You'll need to create it later to activate Prey)"
LangString STANDALONE_MAIL_TO ${LANG_SPANISH} "Mail to"

LangString STANDALONE_SMTP_SERVER ${LANG_SPANISH} "STMP Server"
LangString STANDALONE_SMTP_USERNAME ${LANG_SPANISH} "STMP Username"
LangString STANDALONE_SMTP_PASSWORD ${LANG_SPANISH} "STMP Password"

; -----------------------------------------------------------
; messages

LangString FIRST_TIME_MESSAGE ${LANG_SPANISH} "Prey no está en ejecución. Para echarlo a andar necesitas definir el método de envío de los reportes."
LangString NOT_ADMIN_MESSAGE ${LANG_SPANISH} "El usuario actual no es un administrador. Sólo administradores puede modificar la configuración de Prey."

LangString CONTROL_PANEL_CONFIGURED_MESSAGE ${LANG_SPANISH} "Tu dispositivo ya está sincronizado con el Panel de Control! Quieres volver a realizar este proceso? (No recomendado)"
LangString EMAIL_EXISTS_MESSAGE ${LANG_SPANISH} "La casilla que ingresaste ya existe! ¿Estás seguro que aún no te has registrado?"
LangString INVALID_PARAMS_MESSAGE ${LANG_SPANISH} "Hubo un problema creando tu cuenta. Asegúrate que la casilla de correo ingresada sea válida, y lo mismo con tu contraseña."
LangString ACCOUNT_CREATED_MESSAGE ${LANG_SPANISH} "Cuenta creada! Recuerda que ahora debes verificarla revisando tu correo y clickeando en el link que te enviamos."
LangString UNAUTHORIZED_MESSAGE ${LANG_SPANISH} "No pudimos ingresarte. Recuerda que debes activar tu cuenta abriendo el link que enviamos a tu correo."
LangString PROBLEM_ADDING_DEVICE_MESSAGE ${LANG_SPANISH} "Hubo un problema agregando tu dispositivo. ¿Será que ya agotaste el número de dispositivos dentro de tu cuenta?"
LangString SETTINGS_UPDATED_MESSAGE ${LANG_SPANISH} "Configuración guardada!"

LangString CONFIGURATION_OK_MESSAGE ${LANG_SPANISH} "Configuración OK! Tu computador ya está siendo monitoreado por Prey. $\r$\nFelicitaciones!"

LangString GUEST_ACCOUNT_ADDED_MESSAGE ${LANG_SPANISH} "Guest account ${GUEST_ACCOUNT_NAME} added succesfully."
LangString GUEST_ACCOUNT_REMOVED_MESSAGE ${LANG_SPANISH} "Guest account ${GUEST_ACCOUNT_NAME} removed succesfully."

; -----------------------------------------------------------
; buttons

LangString BACK_BUTTON ${LANG_SPANISH} "< Volver"
LangString NEXT_BUTTON ${LANG_SPANISH} "Siguiente >"
LangString CANCEL_BUTTON ${LANG_SPANISH} "Cancelar"
LangString APPLY_BUTTON ${LANG_SPANISH} "Aceptar"
LangString CREATE_BUTTON ${LANG_SPANISH} "Crear"
LangString CREATING_BUTTON ${LANG_SPANISH} "Creando"
LangString ADD_DEVICE_BUTTON ${LANG_SPANISH} "Agregar"
LangString CONNECTING_BUTTON ${LANG_SPANISH} "Conectando"
LangString ASSOCIATING_BUTTON ${LANG_SPANISH} "Asociando"
