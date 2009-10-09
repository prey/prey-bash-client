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
	!include "isUserAdmin.nsh"
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

 Function .onInit
	!insertmacro IsUserAdmin $0
	${If} $0 == "0"
		messageBox MB_OK "You must be logged in as an administrator user to edit the configuration."
		Abort
	${EndIf}
 FunctionEnd

;--------------------------------
;Variables

	Var POST_METHOD
	Var POST_METHOD_CHANGED
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

		${NSD_CreateLabel} 0 0 100% 10u "Are you using Prey with the control panel (http) or directly to your email?"
		Pop $0

		; POST METHOD
		${ConfigRead} "c:\prey\config" "post_method=" $1
		${GetInQuotes} $1 $POST_METHOD

		${NSD_CreateRadioButton} 0 20 100 12u "http"
		Pop $POST_METHOD
		${NSD_OnClick} $POST_METHOD TogglePostMethod
		${If} $1 == "'http'"
			${NSD_SetState} $POST_METHOD 1
		${EndIf}

		${NSD_CreateRadioButton} 120 20 50 12u "email"
		Pop $POST_METHOD
		${NSD_OnClick} $POST_METHOD TogglePostMethod
		${If} $1 == "'email'"
			${NSD_SetState} $POST_METHOD 1
		${EndIf}

		; API KEY
		${ConfigRead} "c:\prey\config" "api_key=" $3
		${GetInQuotes} $3 $API_KEY

		${NSD_CreateLabel} 0 50 75% 10u "API Key"
		Pop $0
		${NSD_CreateText} 0 65 20% 12u $API_KEY
		Pop $API_KEY
		${NSD_SetTextLimit} $API_KEY 12

		; DEVICE KEY
		${ConfigRead} "c:\prey\config" "device_key=" $4
		${GetInQuotes} $4 $DEVICE_KEY

		${NSD_CreateLabel} 0 90 75% 10u "Device Key"
		Pop $0
		${NSD_CreateText} 0 105 20% 12u $DEVICE_KEY
		Pop $DEVICE_KEY
		${NSD_SetTextLimit} $DEVICE_KEY 6

		${NSD_CreateLabel} 0 145 25% 100u "You can get these $\r$\nboth in Prey's new$\r$\nweb service at$\r$\npreyproject.com."
		Pop $0


		; CHECK URL
		${ConfigRead} "c:\prey\config" "check_url=" $2
		${GetInQuotes} $2 $CHECK_URL

		${NSD_CreateLabel} 120 50 40% 10u "Check URL"
		Pop $0
		${NSD_CreateText} 120 65 63% 12u $CHECK_URL
		Pop $CHECK_URL

		; MAIL TO
		${ConfigRead} "c:\prey\config" "mail_to=" $5
		${GetInQuotes} $5 $MAIL_TO

		${NSD_CreateLabel} 120 90 30% 10u "Mail to"
		Pop $0
		${NSD_CreateText} 120 105 30% 12u $MAIL_TO
		Pop $MAIL_TO

		; SMTP SERVER
		${ConfigRead} "c:\prey\config" "smtp_server=" $6
		${GetInQuotes} $6 $SMTP_SERVER

		${NSD_CreateLabel} 120 130 75% 10u "STMP Server"
		Pop $0
		${NSD_CreateText} 120 145 30% 12u $SMTP_SERVER
		Pop $SMTP_SERVER

		; SMTP USERNAME
		${ConfigRead} "c:\prey\config" "smtp_username=" $7
		${GetInQuotes} $7 $SMTP_USERNAME

		${NSD_CreateLabel} 270 90 75% 10u "STMP Username"
		Pop $0
		${NSD_CreateText} 270 105 30% 12u $SMTP_USERNAME
		Pop $SMTP_USERNAME

		; SMTP PASSWORD
		${ConfigRead} "c:\prey\config" "smtp_password=" $8
		${GetInQuotes} $8 $SMTP_PASSWORD

		${NSD_CreateLabel} 270 130 75% 10u "STMP Password"
		Pop $0
		${NSD_CreatePassword} 270 145 30% 12u $SMTP_PASSWORD
		Pop $SMTP_PASSWORD

		${If} $1 == "'http'"
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
	StrCpy $POST_METHOD_CHANGED "1"
FunctionEnd

Function EnableHTTP
		EnableWindow $API_KEY 1
		EnableWindow $DEVICE_KEY 1
		${NSD_SetText} $CHECK_URL "http://control.preyproject.com"
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

	${If} $POST_METHOD_CHANGED == "1"
		${NSD_GetText} $POST_METHOD $0
		!insertmacro ReplaceInFile "c:\prey\config" "post_method" "post_method='$0'"
	${EndIf}

	${NSD_GetText} $CHECK_URL $0
	${If} "$2" != "'$0'"
		!insertmacro ReplaceInFile "c:\prey\config" "check_url" "check_url='$0'"
	${EndIf}

	${NSD_GetText} $API_KEY $0
	${If} "$3" != "'$0'"
		!insertmacro ReplaceInFile "c:\prey\config" "api_key" "api_key='$0'"
	${EndIf}

	${NSD_GetText} $DEVICE_KEY $0
	${If} "$4" != "'$0'"
		!insertmacro ReplaceInFile "c:\prey\config" "device_key" "device_key='$0'"
	${EndIf}

	${NSD_GetText} $MAIL_TO $0
	${If} "$5" != "'$0'"
		!insertmacro ReplaceInFile "c:\prey\config" "mail_to" "mail_to='$0'"
	${EndIf}

	${NSD_GetText} $SMTP_SERVER $0
	${If} "$6" != "'$0'"
		!insertmacro ReplaceInFile "c:\prey\config" "smtp_server" "smtp_server='$0'"
	${EndIf}

	${NSD_GetText} $SMTP_USERNAME $0
	${If} "$7" != "'$0'"
		!insertmacro ReplaceInFile "c:\prey\config" "smtp_username" "smtp_username='$0'"
	${EndIf}

	${NSD_GetText} $SMTP_PASSWORD $0
	${If} "$8" != "'$0'"
		Base64::Encode "$0"
		Pop $R0
		!insertmacro ReplaceInFile "c:\prey\config" "smtp_password" "smtp_password='$R0'"
	${EndIf}

	${ConfigRead} "c:\prey\config" "post_method=" $0
	${If} $0 == "'http'"
		GetDlgItem $1 $HWNDPARENT 1
		SendMessage $1 ${WM_SETTEXT} 0 "STR:Checking..."
		${NSD_GetText} $API_KEY $3
		${NSD_GetText} $DEVICE_KEY $4
		# Error Code = $0. Output = $1.
		nsExec::ExecToStack '"c:\prey\bin\curl.exe" -s -X PUT http://control.preyproject.com/devices/$4 -d api_key=$3&device[synced]=1'
		Pop $0
		Pop $1
		${If} $1 != "OK"
			MessageBox MB_OK "Synchronization failed. Please make sure your API and Device keys are set up correctly, and the device is not marked as missing."
			GetDlgItem $1 $HWNDPARENT 1
			SendMessage $1 ${WM_SETTEXT} 0 "STR:Apply"
			Abort
		${Else}
			GetDlgItem $1 $HWNDPARENT 1
			SendMessage $1 ${WM_SETTEXT} 0 "STR:OK!"
		${EndIf}
	${EndIf}

	MessageBox MB_OK "Configuration OK! $\r$\nThanks for installing Prey."

FunctionEnd

Section
SectionEnd
