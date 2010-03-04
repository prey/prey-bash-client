; -------------------------------
; Prey Windows Configuration
; By Tomas Pollak (bootlog.org)
; http://preyproject.com
; Licence: GPLv3

;--------------------------------
;Include Modern UI

	!include "MUI2.nsh"
	!include "nsDialogs.nsh"
	!include "InstallOptions.nsh"
	!include "nsis\StringFunctions.nsh"
	!include "nsis\isUserAdmin.nsh"
	!include "nsis\windowsVersion.nsh"

	!include "nsis\NSISpcre.nsh"
	!insertmacro REMatches

	XPStyle on

	;Request application privileges for Windows Vista/7
	RequestExecutionLevel highest

;--------------------------------
; General

	!define CONTROL_PANEL_URL "http://control.preyproject.com"
	!define EXAMPLE_CHECK_URL "http://www.myserver.com/stolen_page"
	!define GUEST_ACCOUNT_NAME "GuestUser"

	Name "Prey"
	OutFile "prey-config.exe"

;--------------------------------
; Language & Interface stuff

  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP "nsis\prey-header.bmp" ; optional

	!ifndef LANGUAGE
		!define LANGUAGE English
	!endif

	!include "nsis\langs\${LANGUAGE}.nsh"

  !define MUI_ABORTWARNING
  !define MUI_ABORTWARNING_TEXT $(ABORT_WARNING)

	Caption $(CAPTION)
	SubCaption 0 $(SUBCAPTION)
  MiscButtonText $(BACK_BUTTON) $(NEXT_BUTTON) $(CANCEL_BUTTON) $(APPLY_BUTTON)
  BrandingText $(BRANDING_TEXT)

	!insertmacro MUI_LANGUAGE "English"
	!insertmacro MUI_LANGUAGE "Spanish"
	; !insertmacro MUI_LANGUAGE "${LANGUAGE}"

;-------------------------------------------
; Pre-checks, is admin? is Prey running?

	Var PREY_PATH
	VAR GUEST_ACCOUNT_EXISTS ; we get the var onload so we call it once (faster)

 Function .onInit

	; check if user is admin
	!insertmacro IsUserAdmin $0
	${If} $0 == "0"
		messageBox MB_OK $(NOT_ADMIN_MESSAGE)
		Abort
	${EndIf}

	; get path
	ReadRegStr $1 HKLM "Software\Prey" "Path"
	${If} $1 != ""
		StrCpy $PREY_PATH "$1"
	${Else}
		StrCpy $PREY_PATH "C:\Prey"
	${EndIf}

  IfSilent 0 +2
		call do_silent_config ; and finish as well (nothing below is run)

	call isPreyRunning
	call checkIfGuestAccountExists

	; call languageSelection
	; messageBox MB_OK $LANGUAGE

 FunctionEnd

;--------------------------------
; installer vars
	Var DESTINY_ONE
	Var DESTINY_TWO
	Var CHOSE_TO_RERUN
	Var IMAGE
	Var IMAGEHANDLE

; prey settings
	Var CURRENT_DELAY
	Var ENABLE_GUEST_ACCOUNT
	Var WIFI_CONNECT
	Var WIFI_CONNECT_ENABLED

; prey base configuration
	Var DELAY
	Var POST_METHOD 		; r1
	Var CHOSEN_POST_METHOD
	Var POST_METHOD_BUTTON ; r1
	Var CHECK_URL 			; r2

; prey control panel configuration
	Var API_KEY 				; r3
	Var DEVICE_KEY			; r4

; prey email configuration
	Var MAIL_TO					; r5
	Var SMTP_SERVER			; r6
	Var SMTP_USERNAME		; r7
	Var SMTP_PASSWORD		;	r8

; temp vars for fetching api and device keys
	Var CONTROL_PANEL_DEVICE_TITLE
	Var CONTROL_PANEL_DEVICE_TYPE

	Var CONTROL_PANEL_NAME
	Var CONTROL_PANEL_EMAIL
	Var CONTROL_PANEL_PASSWORD
	Var CONTROL_PANEL_PASSWORD_TWO

;--------------------------------
;Pages

	Page custom welcomePage welcomePageExit
	Page custom settingsPage settingsPageExit
	Page custom reportsPage reportsPageExit
	Page custom emailPage emailPageExit
	Page custom controlPanelPage controlPanelPageExit
	Page custom newUser newUserExit
	Page custom existingUser existingUserExit

;--------------------------------

Function welcomePage

	!insertmacro MUI_HEADER_TEXT " $(CAPTION)" $(HEADER_TEXT)

	nsDialogs::Create 1018
	Pop $0

	${NSD_CreateLabel} 0 0 100% 10u $(WELCOME_DESC)
	Pop $0

	${NSD_CreateBitmap} 0 40 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\connect.bmp $IMAGEHANDLE

	${NSD_CreateRadioButton} 55 42 200 12u $(SETUP_REPORTS_OPTION)
	Pop $DESTINY_ONE
	${NSD_SetState} $DESTINY_ONE 1

	${NSD_CreateLabel} 57 65 88% 30 $(SETUP_REPORTS_SUMMARY)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	${NSD_CreateHLine} 55 92 88% 3 LabelLine

	${NSD_CreateBitmap} 0 107 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\settings.bmp $IMAGEHANDLE

	${NSD_CreateRadioButton} 55 105 200 12u $(CHANGE_SETTINGS_OPTION)
	Pop $DESTINY_ONE

	${NSD_CreateLabel} 57 130 88% 30 $(CHANGE_SETTINGS_SUMMARY)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	nsDialogs::Show

	${NSD_FreeImage} $IMAGEHANDLE

FunctionEnd

Function welcomePageExit

	${NSD_GetState} $DESTINY_ONE $0
	StrCpy $DESTINY_ONE $0

FunctionEnd

Function settingsPage

	!insertmacro MUI_HEADER_TEXT " $(CAPTION)" $(CHANGE_SETTINGS_TITLE)

	GetDlgItem $1 $HWNDPARENT 1
	SendMessage $1 ${WM_SETTEXT} 0 "STR:$(APPLY_BUTTON)"

	${If} $DESTINY_ONE == 0
		Abort
	${EndIf}

	nsDialogs::Create 1018
	Pop $0

	${NSD_CreateLabel} 0 0 100% 20u $(CHANGE_SETTINGS_DESC)
	Pop $0

	;------------------------------------------
	; delay

	${NSD_CreateBitmap} 0 40 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\delay.bmp $IMAGEHANDLE

	${NSD_CreateDroplist} 55 38 38 12u $DELAY
	Pop $DELAY

  ${NSD_CB_AddString} $DELAY 5
  ${NSD_CB_AddString} $DELAY 10
  ${NSD_CB_AddString} $DELAY 15
  ${NSD_CB_AddString} $DELAY 20
  ${NSD_CB_AddString} $DELAY 25
  ${NSD_CB_AddString} $DELAY 30
  ${NSD_CB_AddString} $DELAY 35
  ${NSD_CB_AddString} $DELAY 40
  ${NSD_CB_AddString} $DELAY 45
  ${NSD_CB_AddString} $DELAY 50
  ${NSD_CB_AddString} $DELAY 55

	call getCurrentDelay

	${NSD_CB_SelectString} $DELAY $CURRENT_DELAY

	${NSD_CreateLabel} 98 42 200 12u $(SETTING_DELAY_TITLE)
	Pop $0

	${NSD_CreateLabel} 57 62 88% 30 $(SETTING_DELAY_DESC)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	;------------------------------------------
	; enable guest account

	${NSD_CreateBitmap} 0 102 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\user.bmp $IMAGEHANDLE

	${NSD_CreateCheckbox} 55 100 200 12u $(SETTING_GUEST_TITLE)
	Pop $ENABLE_GUEST_ACCOUNT

	${If} $GUEST_ACCOUNT_EXISTS == 1 ; guest account exists
		${NSD_SetState} $ENABLE_GUEST_ACCOUNT 1
	${EndIf}

	${NSD_CreateLabel} 57 120 88% 30 $(SETTING_GUEST_DESC)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	;------------------------------------------
	; wifi autoconnect

	${NSD_CreateBitmap} 0 167 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\wifi.bmp $IMAGEHANDLE

	${NSD_CreateCheckbox} 55 165 200 12u $(SETTING_WIFI_TITLE)
	Pop $WIFI_CONNECT

	${ConfigRead} "$PREY_PATH\config" "auto_connect=" $1
	${If} $1 == "'y'"
		StrCpy $WIFI_CONNECT_ENABLED 1
		${NSD_SetState} $WIFI_CONNECT 1
	${EndIf}

	${NSD_CreateLabel} 57 185 88% 30 $(SETTING_WIFI_DESC)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	nsDialogs::Show

FunctionEnd

Function settingsPageExit

	call applyBasicSettings

FunctionEnd

Function reportsPage

	!insertmacro MUI_HEADER_TEXT " $(CAPTION)" $(SETUP_REPORTS_TITLE)

	nsDialogs::Create 1018
	Pop $0

	${NSD_CreateLabel} 0 0 100% 20u $(SETUP_REPORTS_DESC)
	Pop $0

	; POST METHOD
	${ConfigRead} "$PREY_PATH\config" "post_method=" $1
	${GetInQuotes} $1 $POST_METHOD ; global post_method holds the value

	${NSD_CreateBitmap} 0 40 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\controlpanel.bmp $IMAGEHANDLE

	${NSD_CreateRadioButton} 55 42 150 12u $(CONTROL_PANEL_OPTION)
	Pop $POST_METHOD_BUTTON

	${If} $POST_METHOD == "http"
		${NSD_SetState} $POST_METHOD_BUTTON 1
	${EndIf}

	${NSD_CreateLabel} 57 65 88% 30 $(CONTROL_PANEL_SUMMARY)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	${NSD_CreateHLine} 55 99 88% 3 LabelLine

	${NSD_CreateBitmap} 0 107 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\email.bmp $IMAGEHANDLE

	${NSD_CreateRadioButton} 55 105 150 12u $(STANDALONE_OPTION)
	Pop $POST_METHOD_BUTTON

	${If} $POST_METHOD == "email"
		${NSD_SetState} $POST_METHOD_BUTTON 1
	${EndIf}

	${NSD_CreateLabel} 57 130 88% 30 $(STANDALONE_SUMMARY)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	nsDialogs::Show

	${NSD_FreeImage} $IMAGEHANDLE

FunctionEnd

Function reportsPageExit

	; get the variable from the radio button and assign it to the global var (CHOSEN_POST_METHOD)
	${NSD_GetState} $POST_METHOD_BUTTON $0
	${If} $0 == 1
		StrCpy $CHOSEN_POST_METHOD 'email'
	${Else}
		StrCpy $CHOSEN_POST_METHOD 'http'

		${ConfigRead} "$PREY_PATH\config" "api_key=" $1
		${GetInQuotes} $1 $API_KEY

		${If} $API_KEY != ''
			${AndIf} $CHOSE_TO_RERUN != 1
			messageBox MB_YESNO $(CONTROL_PANEL_CONFIGURED_MESSAGE) IDYES proceed
			Abort
			proceed:
			; StrCpy $CHOSE_TO_RERUN 1 ; uncomment this to only show the window once
		${EndIf}

	${EndIf}

FunctionEnd

Function emailPage

	${If} $CHOSEN_POST_METHOD == 'http'
		Abort
	${EndIf}

	nsDialogs::Create 1018
	Pop $0

	${NSD_CreateLabel} 0 0 100% 10u $(STANDALONE_DESC)
	Pop $0

	; CHECK URL
	${ConfigRead} "$PREY_PATH\config" "check_url=" $2
	${GetInQuotes} $2 $CHECK_URL

	${NSD_CreateLabel} 80 50 70% 9u $(STANDALONE_CHECK_URL)
	Pop $0
	${NSD_CreateText} 80 65 63% 12u $CHECK_URL ; url actual
	Pop $CHECK_URL

	; si la URL de chequeo actual es el panel de control
	; mostramos la de ejemplo (ya que estamos en modo email)
	${If} $2 == "'${CONTROL_PANEL_URL}'"
		${NSD_SetText} $CHECK_URL ${EXAMPLE_CHECK_URL}
	${EndIf}

	; MAIL TO
	${ConfigRead} "$PREY_PATH\config" "mail_to=" $5
	${GetInQuotes} $5 $MAIL_TO

	${NSD_CreateLabel} 80 90 30% 9u $(STANDALONE_MAIL_TO)
	Pop $0
	${NSD_CreateText} 80 105 30% 12u $MAIL_TO
	Pop $MAIL_TO

	; SMTP SERVER
	${ConfigRead} "$PREY_PATH\config" "smtp_server=" $6
	${GetInQuotes} $6 $SMTP_SERVER

	${NSD_CreateLabel} 80 130 75% 9u $(STANDALONE_SMTP_SERVER)
	Pop $0
	${NSD_CreateText} 80 145 30% 12u $SMTP_SERVER
	Pop $SMTP_SERVER

	; SMTP USERNAME
	${ConfigRead} "$PREY_PATH\config" "smtp_username=" $7
	${GetInQuotes} $7 $SMTP_USERNAME

	${NSD_CreateLabel} 230 90 75% 9u $(STANDALONE_SMTP_USERNAME)
	Pop $0
	${NSD_CreateText} 230 105 30% 12u $SMTP_USERNAME
	Pop $SMTP_USERNAME

	; SMTP PASSWORD
	; ${ConfigRead} "$PREY_PATH\config" "smtp_password=" $8
	; ${GetInQuotes} $8 $SMTP_PASSWORD

	${NSD_CreateLabel} 230 130 75% 9u $(STANDALONE_SMTP_PASSWORD)
	Pop $0
	${NSD_CreatePassword} 230 145 30% 12u ""
	Pop $SMTP_PASSWORD

	GetDlgItem $1 $HWNDPARENT 1
	SendMessage $1 ${WM_SETTEXT} 0 "STR:$(APPLY_BUTTON)"

	nsDialogs::Show

FunctionEnd

Function emailPageExit

	call applyEmailSettings

FunctionEnd

Function controlPanelPage

	nsDialogs::Create 1018
	Pop $0

	${NSD_CreateLabel} 0 0 100% 20u $(CONTROL_PANEL_DESC)
	Pop $0

	${NSD_CreateBitmap} 0 40 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\user.bmp $IMAGEHANDLE

	${NSD_CreateRadioButton} 55 42 300 12u $(CONTROL_PANEL_NEW_USER_OPTION)
	Pop $DESTINY_TWO
	${NSD_SetState} $DESTINY_TWO 1

	${NSD_CreateLabel} 57 65 88% 30 $(CONTROL_PANEL_NEW_USER_SUMMARY)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	${NSD_CreateBitmap} 0 107 48 48 ""
	Pop $IMAGE
	${NSD_SetImage} $IMAGE pixmaps\conf\user.bmp $IMAGEHANDLE

	${NSD_CreateRadioButton} 55 105 300 12u $(CONTROL_PANEL_EXISTING_USER_TITLE)
	Pop $DESTINY_TWO

	${NSD_CreateLabel} 57 130 88% 30 $(CONTROL_PANEL_EXISTING_USER_SUMMARY)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	nsDialogs::Show

FunctionEnd

Function controlPanelPageExit

	${NSD_GetState} $DESTINY_TWO $0
	StrCpy $DESTINY_TWO $0

FunctionEnd

Function newUser

	${If} $DESTINY_TWO == 1
		Abort
	${EndIf}

	nsDialogs::Create 1018
	Pop $0

	${NSD_CreateLabel} 0 0 100% 20u $(CONTROL_PANEL_NEW_USER_DESC)
	Pop $0

	${NSD_CreateLabel} 0 40 100% 10u $(CONTROL_PANEL_ACCOUNT_SETTINGS)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	${NSD_CreateHLine} 0 58 230 3 LabelLine

	${NSD_CreateLabel} 0 75 80 9u $(CONTROL_PANEL_USER_NAME)
	Pop $0
	${NSD_CreateText} 100 72 27% 12u ""
	Pop $CONTROL_PANEL_NAME

	${NSD_CreateLabel} 0 105 80 9u $(CONTROL_PANEL_USER_EMAIL)
	Pop $0
	${NSD_CreateText} 100 102 27% 12u ""
	Pop $CONTROL_PANEL_EMAIL

	${NSD_CreateLabel} 0 135 80 9u $(CONTROL_PANEL_USER_PASSWORD)
	Pop $0
	${NSD_CreatePassword} 100 132 27% 12u ""
	Pop $CONTROL_PANEL_PASSWORD

	${NSD_CreateLabel} 0 165 90 9u $(CONTROL_PANEL_USER__PASSWORD_TWO)
	Pop $0
	${NSD_CreatePassword} 100 162 27% 12u ""
	Pop $CONTROL_PANEL_PASSWORD_TWO

	call showDeviceSettings

	GetDlgItem $1 $HWNDPARENT 1
	SendMessage $1 ${WM_SETTEXT} 0 "STR:$(CREATE_BUTTON)"

	nsDialogs::Show

FunctionEnd

Function newUserExit

	call createUser
	call addDeviceToUser
	call applyReportSettings

FunctionEnd

Function existingUser

	${If} $DESTINY_TWO == 0
		Abort
	${EndIf}

	nsDialogs::Create 1018
	Pop $0

	; Were not using any back buttons
	; GetFunctionAddress $0 OnBack
	; nsDialogs::OnBack $0

	${NSD_CreateLabel} 0 0 100% 30u $(CONTROL_PANEL_EXISTING_USER_DESC)
	Pop $0

	${NSD_CreateLabel} 0 40 100% 10u $(CONTROL_PANEL_ACCOUNT_SETTINGS)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	${NSD_CreateHLine} 0 58 230 3 LabelLine

	${NSD_CreateLabel} 0 75 80 9u $(CONTROL_PANEL_USER_EMAIL)
	Pop $0
	${NSD_CreateText} 100 72 27% 12u ""
	Pop $CONTROL_PANEL_EMAIL

	${NSD_CreateLabel} 0 105 80 9u $(CONTROL_PANEL_USER_PASSWORD)
	Pop $0
	${NSD_CreatePassword} 100 102 27% 12u ""
	Pop $CONTROL_PANEL_PASSWORD

	call showDeviceSettings

	GetDlgItem $1 $HWNDPARENT 1
	SendMessage $1 ${WM_SETTEXT} 0 "STR:$(ADD_DEVICE_BUTTON)"

	nsDialogs::Show

FunctionEnd

Function existingUserExit

	call getUserKey
	call addDeviceToUser
	call applyReportSettings

	; get api and associate device to user

FunctionEnd

Function showDeviceSettings

	${NSD_CreateLabel} 245 40 100% 10u $(CONTROL_PANEL_DEVICE_SETTINGS)
	Pop $0
	SetCtlColors $0 0x666666 'transparent'

	${NSD_CreateHLine} 245 58 230 3 LabelLine

	${NSD_CreateLabel} 245 75 60 9u $(DEVICE_TITLE)
	Pop $0
	${NSD_CreateText} 310 72 30% 12u ""
	Pop $CONTROL_PANEL_DEVICE_TITLE

	${NSD_CreateLabel} 245 105 60 9u $(DEVICE_TYPE)
	Pop $0

	${NSD_CreateDroplist} 310 102 90 12u
	Pop $CONTROL_PANEL_DEVICE_TYPE

  ${NSD_CB_AddString} $CONTROL_PANEL_DEVICE_TYPE "Portable"
  ${NSD_CB_AddString} $CONTROL_PANEL_DEVICE_TYPE "Desktop"

	${NSD_CB_SelectString} $CONTROL_PANEL_DEVICE_TYPE "Portable"

FunctionEnd

;------------------------------------------------------
; control panel helper functions

Function createUser

	GetDlgItem $1 $HWNDPARENT 1
	SendMessage $1 ${WM_SETTEXT} 0 "STR:$(CREATING_BUTTON)..."

	; get vars to send
	${NSD_GetText} $CONTROL_PANEL_NAME $3
	${NSD_GetText} $CONTROL_PANEL_EMAIL $4
	${NSD_GetText} $CONTROL_PANEL_PASSWORD $5
	${NSD_GetText} $CONTROL_PANEL_PASSWORD_TWO $6

	; Error Code = $0. Output = $1.
	nsExec::ExecToStack '"$PREY_PATH\bin\curl.exe" -s ${CONTROL_PANEL_URL}/users.xml -d "user[name]=$3&user[email]=$4&user[password]=$5&user[password_confirmation]=$6"'

	Pop $0
	Pop $1
	; MessageBox MB_OK $1

	${If} $1 =~ "errors"

		${If} $1 =~ "Email\shas\salready\sbeen\staken"
			MessageBox MB_OK $(EMAIL_EXISTS_MESSAGE)
		${Else}
			MessageBox MB_OK $(INVALID_PARAMS_MESSAGE)
		${EndIf}

		GetDlgItem $1 $HWNDPARENT 1
		SendMessage $1 ${WM_SETTEXT} 0 "STR:Create"
		Abort

	${Else}

		; parse xml to get api key
		${RECaptureMatches} $0 "key>([^<].+)<" $1 1
		Pop $1
		StrCpy $API_KEY $1

		MessageBox MB_OK $(ACCOUNT_CREATED_MESSAGE)

	${EndIf}

FunctionEnd

Function getUserKey

	GetDlgItem $1 $HWNDPARENT 1
	SendMessage $1 ${WM_SETTEXT} 0 "STR:$(CONNECTING_BUTTON)..."

	; get vars to send
	${NSD_GetText} $CONTROL_PANEL_EMAIL $4
	${NSD_GetText} $CONTROL_PANEL_PASSWORD $5

	; Error Code = $0. Output = $1.
	nsExec::ExecToStack '"$PREY_PATH\bin\curl.exe" -s -u $4:$5 ${CONTROL_PANEL_URL}/profile.xml'

	Pop $0
	Pop $1
	; MessageBox MB_OK $1

	${If} $1 =~ "denied"

		MessageBox MB_OK $(UNAUTHORIZED_MESSAGE)

		GetDlgItem $1 $HWNDPARENT 1
		SendMessage $1 ${WM_SETTEXT} 0 "STR:$(ADD_DEVICE_BUTTON)"
		Abort

	${Else}

		; parse xml to get api key
		${RECaptureMatches} $0 "key>([^<].+)<" $1 1
		Pop $1
		StrCpy $API_KEY $1

	${EndIf}

FunctionEnd

Function addDeviceToUser

	GetDlgItem $1 $HWNDPARENT 1
	SendMessage $1 ${WM_SETTEXT} 0 "STR:$(ASSOCIATING_BUTTON)..."

	${NSD_GetText} $CONTROL_PANEL_DEVICE_TITLE $4
	${NSD_GetText} $CONTROL_PANEL_DEVICE_TYPE $5
	${GetWindowsVersion} $6

	; Error Code = $0. Output = $1.
	nsExec::ExecToStack '"$PREY_PATH\bin\curl.exe" -s -u $API_KEY:x ${CONTROL_PANEL_URL}/devices.xml -d "device[title]=$4&device[os]=Windows&device[device_type]=$5&device[os_version]=$6"'

	Pop $0
	Pop $1
	; MessageBox MB_OK $1

	${If} $1 =~ "errors"

		MessageBox MB_OK $(PROBLEM_ADDING_DEVICE_MESSAGE)

		GetDlgItem $1 $HWNDPARENT 1
		SendMessage $1 ${WM_SETTEXT} 0 "STR:$(APPLY_BUTTON)"
		Abort

	${Else}

		; get device key from response
		${RECaptureMatches} $0 "key>([^<].+)<" $1 1
		Pop $1
		StrCpy $DEVICE_KEY $1

	${EndIf}

FunctionEnd

;------------------------------------------------------
; helper functions for applying configuration


Function applyBasicSettings

	${NSD_GetState} $WIFI_CONNECT $0
	${If} $0 == 1 ; wifi connect enabled
		${AndIf} $WIFI_CONNECT_ENABLED != 1
		!insertmacro ReplaceInFile "$PREY_PATH\config" "auto_connect" "auto_connect='y'"
		; MessageBox MB_OK "Wifi activated."
	${ElseIf} $0 != 1 ; wifi_connect disabled
		${AndIf} $WIFI_CONNECT_ENABLED == 1
		!insertmacro ReplaceInFile "$PREY_PATH\config" "auto_connect" "auto_connect='n'"
		; MessageBox MB_OK "Wifi deactivated."
	${EndIf}

	${NSD_GetText} $DELAY $0
	${If} $CURRENT_DELAY != $0
		call setCurrentDelay
	${EndIf}

	${NSD_GetState} $ENABLE_GUEST_ACCOUNT $0
	${If} $0 == 1 ; guest account checkbox enabled
		${AndIf} $GUEST_ACCOUNT_EXISTS != 1
			call createGuestAccount
			Pop $0
			Pop $1
			${If} $1 == 0
				MessageBox MB_OK $(GUEST_ACCOUNT_ADDED_MESSAGE)
			${EndIf}
	${ElseIf} $0 != 1 ; guest account checkbox disabled
		${AndIf} $GUEST_ACCOUNT_EXISTS == 1
			call removeGuestAccount
			Pop $0
			Pop $1
			${If} $1 == 0
				MessageBox MB_OK  $(GUEST_ACCOUNT_REMOVED_MESSAGE)
			${EndIf}
	${EndIf}

	MessageBox MB_OK $(SETTINGS_UPDATED_MESSAGE)
	Quit

FunctionEnd

Function applyReportSettings

	${If} $POST_METHOD == "email" ; change if its currently email
		!insertmacro ReplaceInFile "$PREY_PATH\config" "post_method" "post_method='http'"
	${EndIf}

	; lets make sure the right check url gets set
	; in case the var is currently empty, or its different than what it should be
	${If} $CHECK_URL == ''
		${OrIf} $CHECK_URL != $CONTROL_PANEL_URL
		!insertmacro ReplaceInFile "$PREY_PATH\config" "check_url" "check_url='${CONTROL_PANEL_URL}'"
	${EndIf}

	!insertmacro ReplaceInFile "$PREY_PATH\config" "api_key" "api_key='$API_KEY'"
	!insertmacro ReplaceInFile "$PREY_PATH\config" "device_key" "device_key='$DEVICE_KEY'"

	call exitConfigurator

FunctionEnd

Function applyEmailSettings

	${If} $POST_METHOD == "http" ; change if its currently http
		!insertmacro ReplaceInFile "$PREY_PATH\config" "post_method" "post_method='email'"
	${EndIf}

	${NSD_GetText} $CHECK_URL $0
	${If} "$CHECK_URL" != "$0"
		!insertmacro ReplaceInFile "$PREY_PATH\config" "check_url" "check_url='$0'"
	${EndIf}

	${NSD_GetText} $MAIL_TO $0
	${If} "$MAIL_TO" != "$0"
		!insertmacro ReplaceInFile "$PREY_PATH\config" "mail_to" "mail_to='$0'"
	${EndIf}

	${NSD_GetText} $SMTP_SERVER $0
	${If} "$SMTP_SERVER" != "$0"
		!insertmacro ReplaceInFile "$PREY_PATH\config" "smtp_server" "smtp_server='$0'"
	${EndIf}

	${NSD_GetText} $SMTP_USERNAME $0
	${If} "$SMTP_USERNAME" != "$0"
		!insertmacro ReplaceInFile "$PREY_PATH\config" "smtp_username" "smtp_username='$0'"
	${EndIf}

	${NSD_GetText} $SMTP_PASSWORD $0
	${If} "$0" != ""
		Base64::Encode "$0"
		Pop $R0
		!insertmacro ReplaceInFile "$PREY_PATH\config" "smtp_password" "smtp_password='$R0'"
	${EndIf}

	call exitConfigurator

FunctionEnd

Function do_silent_config

	!include FileFunc.nsh
	!insertmacro GetParameters
	!insertmacro GetOptions

	${GetParameters} $R0
	ClearErrors
	${GetOptions} $R0 /API_KEY= $API_KEY
	${GetOptions} $R0 /DEVICE_KEY= $DEVICE_KEY

	${If} $API_KEY == ''
		${OrIf} $DEVICE_KEY == ''
			MessageBox MB_OK 'No API or Device keys entered. Try again.'
			Abort
	${EndIf}

	call applyReportSettings
FunctionEnd

Function exitConfigurator

	; other users may not modify our config file
	AccessControl::GrantOnFile "$PREY_PATH\config" "(BU)" "GenericRead"

	; lets run (or rerun) prey with the new configuration
	Exec '"$PREY_PATH\platform\windows\cron.exe" --log'

	IfSilent 0 +2 ; dont show shit!
		Quit

	MessageBox MB_OK $(CONFIGURATION_OK_MESSAGE)
	Quit

FunctionEnd

Function isPreyRunning

	Processes::FindProcess "cron.exe"
	${If} $R0 == "0"
		messageBox MB_OK|MB_ICONINFORMATION $(FIRST_TIME_MESSAGE)
		; Abort
	${EndIf}

FunctionEnd

Function getCurrentDelay

	ReadRegStr $1 HKLM "Software\Prey" "Delay"
	Math::Script "R0 = $1 / (60 * 1000)"
	StrCpy $CURRENT_DELAY $R0

FunctionEnd

Function setCurrentDelay

	${NSD_GetText} $DELAY $1
	Math::Script "R0 = $1 * (60 * 1000)"
	WriteRegStr HKLM "Software\Prey" "Delay" "$R0"

FunctionEnd

Function checkIfGuestAccountExists
	nsExec::ExecToStack 'net user ${GUEST_ACCOUNT_NAME}'
	Pop $0
	Pop $1

	${If} $0 == 0
		; messageBox MB_OK "Guest account ${GUEST_ACCOUNT_NAME} exists!"
		StrCpy $GUEST_ACCOUNT_EXISTS 1
	${EndIf}

FunctionEnd

Function createGuestAccount
	nsExec::ExecToStack 'net user ${GUEST_ACCOUNT_NAME} /add'
	Pop $1
	Pop $0
FunctionEnd

Function removeGuestAccount
	nsExec::ExecToStack 'net user ${GUEST_ACCOUNT_NAME} /delete'
	Pop $1
	Pop $0
FunctionEnd

Function languageSelection

	Push ""
	Push ${LANG_ENGLISH}
	Push English
	Push ${LANG_SPANISH}
	Push Spanish
	Push A ; A means auto count languages
	       ; for the auto count to work the first empty push (Push "") must remain
	LangDLL::LangDialog "Installer Language" "Please select the language of the installer"

	Pop $LANGUAGE
	StrCmp $LANGUAGE "cancel" 0 +2
		Abort

FunctionEnd

Section
SectionEnd ; this is only for the thingy to compile
