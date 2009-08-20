; -------------------------------
; Prey Windows Installer Script
; By Tomas Pollak (bootlog.org)
; http://preyproject.com
; Licence: GPLv3

;--------------------------------
;Include Modern UI

	!include "MUI2.nsh"
	XPStyle on

;--------------------------------
;General

	;Name and file
	Name "Prey"
	OutFile "prey-installer-0.3-win32.exe"

	;Default installation folder
	;InstallDir "$LOCALAPPDATA\Prey"
	InstallDir "c:\Prey"

	;Get installation folder from registry if available
	InstallDirRegKey HKCU "Software\Prey" ""

	;Request application privileges for Windows Vista
	RequestExecutionLevel highest

;--------------------------------
;Variables

	Var StartMenuFolder

;--------------------------------
;Interface Settings

	!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"
	!define MUI_ABORTWARNING

;--------------------------------
;Pages

	!insertmacro MUI_PAGE_WELCOME
	!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"
	;!insertmacro MUI_PAGE_COMPONENTS
	;!insertmacro MUI_PAGE_DIRECTORY

	; Page custom nsDialogsPage

	;Start Menu Folder Page Configuration
	!define MUI_STARTMENUPAGE_REGISTRY_ROOT "SHCTX"
	!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Prey"
	!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"

	!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

	!insertmacro MUI_PAGE_INSTFILES
	!define MUI_FINISHPAGE_RUN "$INSTDIR\prey-config.exe"
	; !define MUI_FINISHPAGE_RUN "$PROGRAMFILES\Windows NT\Accessories\wordpad.exe"
	; !define MUI_FINISHPAGE_RUN_PARAMETERS "$INSTDIR\config"
	!define MUI_FINISHPAGE_RUN_TEXT "Configure Prey Settings (Recommended)"
	!insertmacro MUI_PAGE_FINISH

	!insertmacro MUI_UNPAGE_CONFIRM
	!insertmacro MUI_UNPAGE_INSTFILES
	!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages

	!insertmacro MUI_LANGUAGE "English"
	!insertmacro MUI_LANGUAGE "Spanish"

;--------------------------------
;Installer Sections

Section "Prey" PreySection

	SetOutPath "$INSTDIR"
	; %NSIS_INSTALL_FILES

	File /r /x .* ..\..\prey.sh
	File /r /x .* ..\..\config
	File /r /x .* ..\..\README
	File /r /x .* ..\..\lang

	; windows specific stuff
	File /r /x .* prey.bat
	File /r /x .* prey-config.exe
	File /r /x .* etc

	SetOutPath "$INSTDIR\bin"
	File /x .* bin\*.*

	SetOutPath "$INSTDIR\platform"
	File /r /x .* ..\..\platform\base
	File /r /x .* ..\..\platform\windows

	SetOutPath "$INSTDIR\lib"
	File /r /x .* ..\..\lib\*.*

	SetOutPath "$INSTDIR\modules"
	File /r /x /a .* ..\..\modules\alert
	File /r /x /a .* ..\..\modules\network
	File /r /x /a .* ..\..\modules\session
	File /r /x /a .* ..\..\modules\webcam
	;File /r /x /a .* ..\..\modules\geo

	SetOutPath "$INSTDIR\modules\network"
	File /r /x /a .* active

	SetOutPath "$INSTDIR\modules\session"
	File /r /x /a .* active

	SetOutPath "$INSTDIR\modules\webcam"
	File /r /x /a .* active

	SetOutPath "$INSTDIR"

	;Create uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"

	!insertmacro MUI_STARTMENU_WRITE_BEGIN Application

		;Create shortcuts
		CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
		; CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Prey.lnk" "$INSTDIR\prey.bat"
		; CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Configure Prey.lnk" "$PROGRAMFILES\Windows NT\Accessories\wordpad.exe" "$INSTDIR\config"
		CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Configure Prey.lnk" "$INSTDIR\prey-config.exe"
		CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

	!insertmacro MUI_STARTMENU_WRITE_END

	; add scheduled task
	nsExec::Exec '"schtasks.exe" -create -ru "System" -sc MINUTE -mo 10 -tn "Prey" -tr "$INSTDIR\prey.bat"'

SectionEnd

;--------------------------------
;Descriptions

	;Language strings
	LangString DESC_PreySection ${LANG_ENGLISH} "Prey application and modules."
	LangString DESC_PreySection ${LANG_SPANISH} "Aplicacion y modulos para Prey."

	;Assign language strings to sections
	!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
		!insertmacro MUI_DESCRIPTION_TEXT ${PreySection} $(DESC_PreySection)
	!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Section "Uninstall"

	RMDir /r "$INSTDIR\bin"
	RMDir /r "$INSTDIR\etc"
	RMDir /r "$INSTDIR\platform"
	RMDir /r "$INSTDIR\lang"
	RMDir /r "$INSTDIR\lib"
	RMDir /r "$INSTDIR\modules"

	;%NSIS_UNINSTALL_FILES

	Delete "$INSTDIR\.bash_history"
	Delete "$INSTDIR\README"
	Delete "$INSTDIR\prey.bat"
	Delete "$INSTDIR\prey.sh"
	Delete "$INSTDIR\config"
	Delete "$INSTDIR\Uninstall.exe"

	RMDir "$INSTDIR"

	!insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder

	Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
	Delete "$SMPROGRAMS\$StartMenuFolder\Configure Prey.lnk"
	; Delete "$SMPROGRAMS\$StartMenuFolder\Prey.lnk"
	RMDir "$SMPROGRAMS\$StartMenuFolder"

	DeleteRegKey /ifempty HKCU "Software\Prey"

	; delete prey scheduled task
	nsExec::Exec '"schtasks.exe" -delete -f -tn "Prey"'

SectionEnd
