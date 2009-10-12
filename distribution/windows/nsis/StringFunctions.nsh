Function ConfigRead
	!define ConfigRead `!insertmacro ConfigReadCall`

	!macro ConfigReadCall _FILE _ENTRY _RESULT
		Push `${_FILE}`
		Push `${_ENTRY}`
		Call ConfigRead
		Pop ${_RESULT}
	!macroend

	Exch $1
	Exch
	Exch $0
	Exch
	Push $2
	Push $3
	Push $4
	ClearErrors

	FileOpen $2 $0 r
	IfErrors error
	StrLen $0 $1
	StrCmp $0 0 error

	readnext:
	FileRead $2 $3
	IfErrors error
	StrCpy $4 $3 $0
	StrCmp $4 $1 0 readnext
	StrCpy $0 $3 '' $0
	StrCpy $4 $0 1 -1
	StrCmp $4 '$\r' +2
	StrCmp $4 '$\n' 0 close
	StrCpy $0 $0 -1
	goto -4

	error:
	SetErrors
	StrCpy $0 ''

	close:
	FileClose $2

	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd

!macro ReplaceInFile SOURCE_FILE SEARCH_TEXT REPLACEMENT
  Push "${SOURCE_FILE}"
  Push "${SEARCH_TEXT}"
  Push "${REPLACEMENT}"
  Call ReplaceLineStr
!macroend

Function ReplaceLineStr

 Exch $R0 ; string to replace that whole line with
 Exch
 Exch $R1 ; string that line should start with
 Exch
 Exch 2
 Exch $R2 ; file
 Push $R3 ; file handle
 Push $R4 ; temp file
 Push $R5 ; temp file handle
 Push $R6 ; global
 Push $R7 ; input string length
 Push $R8 ; line string length
 Push $R9 ; global

  StrLen $R7 $R1

  GetTempFileName $R4

  FileOpen $R5 $R4 w
  FileOpen $R3 $R2 r

  ReadLoop:
  ClearErrors
   FileRead $R3 $R6
    IfErrors Done

   StrLen $R8 $R6
   StrCpy $R9 $R6 $R7 -$R8
   StrCmp $R9 $R1 0 +3

    FileWrite $R5 "$R0$\r$\n"
    Goto ReadLoop

    FileWrite $R5 $R6
    Goto ReadLoop

  Done:

  FileClose $R3
  FileClose $R5

  SetDetailsPrint none
   Delete $R2
   Rename $R4 $R2
  SetDetailsPrint both

 Pop $R9
 Pop $R8
 Pop $R7
 Pop $R6
 Pop $R5
 Pop $R4
 Pop $R3
 Pop $R2
 Pop $R1
 Pop $R0
FunctionEnd

Function GetInQuotes
	!define GetInQuotes `!insertmacro GetInQuotesCall`

	!macro GetInQuotesCall _STRING _RESULT
		Push `${_STRING}`
		Call GetInQuotes
		Pop ${_RESULT}
	!macroend

	Exch $R0
	Push $R1
	Push $R2
	Push $R3

 StrCpy $R2 -1
 IntOp $R2 $R2 + 1
  StrCpy $R3 $R0 1 $R2
  StrCmp $R3 "" 0 +3
   StrCpy $R0 ""
   Goto Done
  StrCmp $R3 "'" 0 -5

 IntOp $R2 $R2 + 1
 StrCpy $R0 $R0 "" $R2

 StrCpy $R2 0
 IntOp $R2 $R2 + 1
  StrCpy $R3 $R0 1 $R2
  StrCmp $R3 "" 0 +3
   StrCpy $R0 ""
   Goto Done
  StrCmp $R3 "'" 0 -5

 StrCpy $R0 $R0 $R2
 Done:

Pop $R3
Pop $R2
Pop $R1
Exch $R0
FunctionEnd
