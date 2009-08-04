; -------------------------------
; Prey Windows Installer Script
; By Tomas Pollak (bootlog.org)
; http://preyproject.com
; Licence: GPLv3

;--------------------------------
;Include Modern UI

	!include "MUI2.nsh"
	!include "nsDialogs.nsh"
	!include "StringFunctions.nsh"

	XPStyle on

;--------------------------------
;General

	;Name and file
	Name "Prey"
	Caption "Prey Configurator"
	SubCaption 0 "Settings for Prey"
	OutFile "prey-config.exe"

	MiscButtonText "Back" "Next" "Cancel" "Apply"

	;Request application privileges for Windows Vista
	RequestExecutionLevel highest

;--------------------------------
;Variables

	Var POST_METHOD
	Var API_KEY
	Var DEVICE_KEY
	Var CHECK_URL
	Var MAIL_TO
	Var SMTP_SERVER
	Var SMTP_USERNAME
	Var SMTP_PASSWORD

;--------------------------------
;Pages

	Page custom nsDialogsPage nsDialogsPageLeave

;--------------------------------
;Languages

	!insertmacro MUI_LANGUAGE "English"
	!insertmacro MUI_LANGUAGE "Spanish"

Function nsDialogsPage

		nsDialogs::Create 1018
		Pop $0

		GetFunctionAddress $0 OnBack
		nsDialogs::OnBack $0

		${NSD_CreateLabel} 0 0 150 10u "Data posting method"
		Pop $0

		${ConfigRead} "c:\prey\config" "post_method=" $7
		${GetInQuotes} $7 $POST_METHOD

		${NSD_CreateRadioButton} 0 20 100 12u "http"
		Pop $POST_METHOD
		${NSD_OnClick} $POST_METHOD TogglePostMethod
		${If} $7 == "'http'"
			${NSD_SetState} $POST_METHOD 1
		${EndIf}

		${NSD_CreateRadioButton} 120 20 50 12u "email"
		Pop $POST_METHOD
		${NSD_OnClick} $POST_METHOD TogglePostMethod
		${If} $7 == "'email'"
			${NSD_SetState} $POST_METHOD 1
		${EndIf}

		${ConfigRead} "c:\prey\config" "check_url=" $6
		${GetInQuotes} $6 $CHECK_URL

		${NSD_CreateLabel} 270 0 75% 10u "Check URL"
		Pop $0
		${NSD_CreateText} 270 20 40% 12u $CHECK_URL
		Pop $CHECK_URL

		${ConfigRead} "c:\prey\config" "api_key=" $0
		${GetInQuotes} $0 $API_KEY

		${NSD_CreateLabel} 0 50 75% 10u "API Key"
		Pop $0
		${NSD_CreateText} 0 65 20% 12u $API_KEY
		Pop $API_KEY

		${NSD_CreateLabel} 0 145 25% 100u "You can get these $\r$\nboth in Prey's new$\r$\nweb service at$\r$\nwww.preyproject.com."
		Pop $0

		${ConfigRead} "c:\prey\config" "device_key=" $1
		${GetInQuotes} $1 $DEVICE_KEY

		${NSD_CreateLabel} 0 90 75% 10u "Device Key"
		Pop $0
		${NSD_CreateText} 0 105 20% 12u ""
		Pop $DEVICE_KEY

		${ConfigRead} "c:\prey\config" "mail_to=" $2
		${GetInQuotes} $2 $MAIL_TO

		${NSD_CreateLabel} 120 50 75% 10u "Mail to"
		Pop $0
		${NSD_CreateText} 120 65 30% 12u $MAIL_TO
		Pop $MAIL_TO

		${ConfigRead} "c:\prey\config" "smtp_server=" $3
		${GetInQuotes} $3 $SMTP_SERVER

		${NSD_CreateLabel} 120 90 75% 10u "STMP Server"
		Pop $0
		${NSD_CreateText} 120 105 30% 12u $SMTP_SERVER
		Pop $SMTP_SERVER

		${ConfigRead} "c:\prey\config" "smtp_username=" $4
		${GetInQuotes} $4 $SMTP_USERNAME

		${NSD_CreateLabel} 120 130 75% 10u "STMP Username"
		Pop $0
		${NSD_CreateText} 120 145 30% 12u $SMTP_USERNAME
		Pop $SMTP_USERNAME

		${ConfigRead} "c:\prey\config" "smtp_password=" $5
		${GetInQuotes} $5 $SMTP_PASSWORD

		${NSD_CreateLabel} 120 170 75% 10u "STMP Password"
		Pop $0
		${NSD_CreatePassword} 120 185 30% 12u $SMTP_PASSWORD
		Pop $SMTP_PASSWORD

		${If} $7 == "'http'"
			Call EnableHTTP
		${Else}
			Call EnableEmail
		${EndIf}

		nsDialogs::Show

	FunctionEnd

Function TogglePostMethod
	Pop $POST_METHOD
	${NSD_GetText} $POST_METHOD $0
	${If} $0 == "http"
		Call EnableHTTP
	${Else}
		Call EnableEmail
	${EndIf}
FunctionEnd

Function EnableHTTP
		EnableWindow $API_KEY 1
		EnableWindow $DEVICE_KEY 1
		${NSD_SetText} $CHECK_URL "http://preyproject.com"
		EnableWindow $CHECK_URL 0
		EnableWindow $MAIL_TO 0
		EnableWindow $SMTP_SERVER 0
		EnableWindow $SMTP_USERNAME 0
		EnableWindow $SMTP_PASSWORD 0
FunctionEnd

Function EnableEmail
		EnableWindow $API_KEY 0
		EnableWindow $DEVICE_KEY 0
		EnableWindow $CHECK_URL 1
		EnableWindow $MAIL_TO 1
		EnableWindow $SMTP_SERVER 1
		EnableWindow $SMTP_USERNAME 1
		EnableWindow $SMTP_PASSWORD 1
FunctionEnd

Function OnBack

	MessageBox MB_YESNO "Inserted values will be lost. Are you sure?" IDYES +2
	Abort

FunctionEnd

Function nsDialogsPageLeave

	${NSD_GetText} $POST_METHOD $0
	!insertmacro ReplaceInFile "c:\prey\config" "post_method" "post_method='$0'"

	${NSD_GetText} $API_KEY $0
	!insertmacro ReplaceInFile "c:\prey\config" "api_key" "api_key='$0'"

	${NSD_GetText} $DEVICE_KEY $0
	!insertmacro ReplaceInFile "c:\prey\config" "device_key" "device_key='$0'"

	${NSD_GetText} $CHECK_URL $0
	!insertmacro ReplaceInFile "c:\prey\config" "check_url" "check_url='$0'"

	${NSD_GetText} $MAIL_TO $0
	!insertmacro ReplaceInFile "c:\prey\config" "mail_to" "mail_to='$0'"

	${NSD_GetText} $SMTP_SERVER $0
	!insertmacro ReplaceInFile "c:\prey\config" "smtp_server" "smtp_server='$0'"

	${NSD_GetText} $SMTP_USERNAME $0
	!insertmacro ReplaceInFile "c:\prey\config" "smtp_username" "smtp_username='$0'"

	${NSD_GetText} $SMTP_PASSWORD $0
	${If} "$5" != "'$0'"
	Base64::Encode "$0"
	Pop $R0
	!insertmacro ReplaceInFile "c:\prey\config" "smtp_password" "smtp_password='$R0'"
	${EndIf}

FunctionEnd

Section
SectionEnd
