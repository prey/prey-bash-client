/*
_____________________________________________________________________________

                       PCRE Functions Header v1.0
_____________________________________________________________________________

An NSIS plugin providing Perl compatible regular expression functions.

A simple wrapper around the excellent PCRE library which was written by
Philip Hazel, University of Cambridge.

For those that require documentation on how to construct regular expressions,
please see http://www.pcre.org/

_____________________________________________________________________________

Copyright (c) 2007 Computerway Business Solutions Ltd.
Copyright (c) 2005 Google Inc.
Copyright (c) 1997-2006 University of Cambridge

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the name of Google
      Inc. nor the name of Computerway Business Solutions Ltd. nor the names
      of their contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Core PCRE Library Written by:       Philip Hazel, University of Cambridge
C++ Wrapper functions by:           Sanjay Ghemawat, Google Inc.
Support for PCRE_XXX modifiers by:  Giuseppe Maxia
NSIS integration by:                Rob Stocks, Computerway Business Solutions Ltd.

_____________________________________________________________________________

Usage:
======

  ...
  # include this header
  !include NSISpcre.nsh
  ...
  # include any functions that will be used in the installer
  !insertmacro RESetOption
  !insertmacro REClearOption
  !insertmacro REGetOption
  !insertmacro REClearAllOptions
  !insertmacro REMatches
  !insertmacro RECaptureMatches
  !insertmacro REReplace
  ...
  # include any functions that will be used in the uninstaller
  !insertmacro un.RESetOption
  !insertmacro un.REClearOption
  !insertmacro un.REGetOption
  !insertmacro un.REClearAllOptions
  !insertmacro un.REMatches
  !insertmacro un.RECaptureMatches
  !insertmacro un.REReplace
  ...
  # Use a function or integrate with LogicLib
  Section|Function ...
        ...
        ${REMatches} $0 ^A(.*)Z" "ABC...XYZ" 0
        ...
        ${If} "subject" =~ "pattern"
        ...
        ${EndIf}
        ...
  SectionEnd|FunctionEnd
  ...
  
  See NSISpcreTest.nsi for examples.
  
LogicLib Integration:
=====================

        By including this header, two additional string "operators" are added to LogicLib
        as follows:
        
        a =~ b     Test if subject a matches pattern b
        a !~ b     Test if subject a does not match pattern b
        
        E.g.
        
        ${If} $0 =~ ".*\\"
                # $0 has a trailing backslash
        ${Else}
                # $0 does not have a trailing backslash
        ${EndIf}

        ${If} $0 !~ "http://.*"
                # $0 does not start "http://"
        ${Else}
                # $0 does start with "http://"
        ${EndIf}

        You must insert the REMatches function in order to use these "operators" with:
        
        !insertmacro REMatches
        or
        !insertmacro un.REMatches
        
        To integrate with LogicLib in the uninstaller, prefix the operators with 'un.'
        as follows:
        
        ${If} $0 un.=~ ".*\\"
                ...
        ${EndIf}

Available Functions:
====================

  RECheckPattern RESULT PATTERN
  
        Checks whether the supplied regular expression string is valid.
        
        E.g. ${RECheckPattern} $0 ".*"
                # Will return "" becasue the pattern is valid
             ${RECheckPattern} $0 "(.*"
                # Will return an error because of the unmatched bracket
        
        Params:
        
        RESULT (output)
        
        The result of the test. An empty string if PATTERN is ok otherwise a
        description of what was wrong with it. 
        
        PATTERN (input)
        
        See REMatches.
        
        Notes:
        
        Unlike the other functions, this function does not set the error flag if
        the supplied PATTERN is invalid.
        
  REQuoteMeta RESULT SUBJECT
  
        Escapes characters in the subject so the entire string will be interpreted
        literally.
        
        E.g. ${REQuoteMeta} $0 ".*"
                # Will return "\.\*"
        
        Params:
        
        RESULT (output)
        
        The converted from of SUBJECT with special characters escaped.
        
        SUBJECT (input)
        
        The string to convert.
        
  REMatches RESULT PATTERN SUBJECT PARTIAL
  
        Test whether a string matches a regular expression.
        
        E.g. ${REMatches} $0 "A(.*)Z" "ABC...XYZ" 0
                # Will return "true"
             ${REMatches} $0 "A(.*)" "ABC...XYZ" 0
                # Will return "false" because partial matching wasn't requested
             ${REMatches} $0 "A(.*)" "ABC...XYZ" 1
                # Will return "true" because partial matching was requested

        Params:
        
        RESULT (output)
        
        The result of the test. After the call, the return variable will contain
        one of the following values:
          "true"        The string in SUBJECT matches the PATTERN
          "false"       The string in SUBJECT does not match the PATTERN
          "error <msg>" There was an error compiling the PATTERN. The
                        error text will be returned after the word error.
                        The error flag will be set in this case.
                        
        PATTERN (input)
        
        The PCRE-compatible regular expression to check for (without the leading
        and trailing slashes and without any options). E.g. '.+' (not '/.+/s').
        See http://www.pcre.org/ for documentation & examples.
        
        SUBJECT (input)
        
        The string to test.
        
        PARTIAL (input)
        
        Either 1 or 0. Pass the value 1 to enable partial matches (part of the
        SUBJECT string must match the PATTERN string) or 0 to force full matches
        (the whole SUBJECT string must match the PATTERN string).
        
        Notes:
        
        See SetOptions for more control over pattern matching (e.g. case sensitivity).
        The PARTIAL option is ignored if in multiline mode.
        
  RECaptureMatches RESULT PATTERN SUBJECT PARTIAL
  
        Test whether a string matches a regular expression and return any substrings
        captured.

        E.g. ${RECaptureMatches} $0 "([^=]+)=(.+)" "pcre=excellent"
                        # Will return 2 in $0 because 2 strings were captured
                Pop $1  # Will contain "pcre"
                Pop $2  # Will contain "excellent"
                
        Params:

        RESULT (output)
        
        The string "false" if SUBJECT does not match PATTERN.
        The number of substrings captured by capture groups if SUBJECT does match
        PATTERN.
        The string "error" followed by an error message if there was a problem
        compiling PATTERN (the error flag will be set in this case).
        
        PATTERN (input)
        
        See REMatches.
        
        SUBJECT (input)
        
        See REMatches.
        
        PARTIAL (input)
        
        See REMatches.
        
        Notes:
        
        This function is the same as REMatches except that if SUBJECT matches PATTERN,
        the number of substring captured is returned instead of the string "true". Also,
        each captured string is available on the stack in left-to-right order of capture.
        To use this function, first read the RESULT. If the error flag is not set and
        RESULT is not "false", read it as an integer and pop that number of values from
        the stack (these will be the captured substrings).
        
        This function can return 0 on a successful match indicating that SUBJECT matches
        the PATTERN but that no substrings were captured (e.g. because no capture groups
        were specified or because the NO_AUTO_CAPTURE option was set).
        
  REFind RESULT PATTERN SUBJECT
  REFindNext RESULT
  REFindClose

        Extracts captured substrings from SUBJECT according to PATTERN and advances the
        position in SUBJECT so subsequent calls to REFindNext will obtain the next set
        of captured substrings.
        
        E.g. ${REFind} "([0-9]+)" "123 456"
                        # Will capture "123"
             ${REFindNext}
                        # Will capture "456"
             ${REFindClose}
             
        Params:
        
        RESULT (output)
        
        Does not apply to REFindClose which has no parameters.
        See RECaptureMatches.
        For REFindNext, RESULT will be "false" if there were no more matches.
        
        PATTERN (input)
        
        Only applies to REFind.
        See REMatches.
        
        SUBJECT (input)
        
        Only applies to REFind.
        See REMatches.

        Notes:
        
        Partial matching is always enabled.
        Not compatible with the NO_AUTO_CAPTURE option (see RESetOption).
        PATTERNS containing no capture groups will be bracketed to create a single
        capture group that matches the entire pattern.
        REFindClose must be called to free resources in the plugin. It may only be
        omitted if REFind is called again since this will automatically free any
        resources allocated by a previous call to REFind.
        
  REReplace RESULT PATTERN SUBJECT REPLACEMENT REPLACEALL
  
        Replaces one or all occurances of PATTERN found in SUBJECT with REPLACEMENT.
        
        E.g. ${REReplace} $0 "h(.*)" "hello world!" "H\1" 0
        
        Params:

        RESULT (output)
        
        The SUBJECT string with any replacements made. If no matches of PATTERN were
        found in SUBJECT, an empty string will be returned. If there was an error
        compiling PATTERN, the error flag will be set and the error will be returned.
        
        PATTERN (input)
        
        See REMatches. The regular expression to search for. Up to 9 captured substrings
        can be referenced (by number 1-9) in the REPLACEMENT string if required.
        
        SUBJECT (input)
        
        The string on which to perform the replacements.
        
        REPLACEMENT (input)
        
        The string to replace occurances of PATTERN with. This string may refer to up to
        9 captured substrings defined in PATTERN by using '\1' to '\9'.

        REPLACEALL
        
        Either 0 or 1. To replace only the first occurance of PATTERN in SUBJECT with
        REPLACEMENT, specify 0. To replace all occurances, specify 1.
        
  REClearAllOptions
  
        Clears all options and reverts to default PCRE pattern matching behaviour.
        
        E.g. ${REClearAllOptions}
        
        Params:

        No parameters.
        
        Notes:
        
        See RESetOption for a list of available options.
        
  RESetOption OPTION
  
        Sets the option specified in OPTION (turns it on).
        
        E.g. ${RESetOption} "CASELESS"
        
        Params:

        OPTION (input)
        
        The option to set. One of the following strings:
        
          CASELESS
                Perform case-insensitive matching
          MULTILINE
                Enable matching of individual lines. '^' and '$' can be used to
                match the starts and ends of lines instead of the start and end
                of the subject string. Forces partial matching.
          DOTALL
                Allow '.' to match newlines within the subject.
          EXTENDED
                Ignore whitespace & comments in patterns
          DOLLAR_ENDONLY
                When not in multiline mode, force '$' to match only the end of the
                entire string (otherwise it will also match prior to the last
                newline if that newline terminates the string)
          EXTRA
                See PCRE documentation.
          UTF8
                Enable UTF8 handling (untested from NSIS).
          UNGREEDY
                Set quantifiers to be ungreedy by default instead of greedy. This
                also reverses the meaning of the '?' ungreedy qualifier to mean
                greedy.
          NO_AUTO_CAPTURE
                Don't capture subgroups.
          m
                Synonym for MULTILINE (Perl syntax).
          i
                Synonym for CASELESS (Perl syntax).
          s
                Synonym for DOTALL (Perl syntax).
          x
                Synonym for EXTENDED (Perl syntax).
                
        Notes:
        
        Once set, the option will apply to all further calls until cleared.
        
  REClearOption OPTION
  
        Clears the option specified in OPTION (turns it off).
        
        E.g. ${REClearOption} "CASELESS"
        
        Params:
        
        OPTION (input)
        
        See RESetOption.
                        
        Notes:

        Once cleared, the option will not apply to all further calls until set.
        
  REGetOption RESULT OPTION
  
        Obtains the current state of the specified OPTION.
        
        E.g. ${REGetOption} $0 "CASELESS"
        
        Params:
        
        RESULT (output)
        
        The state of the option: "true" if set and "false" otherwise.

        OPTION (input)

        See RESetOption.

_____________________________________________________________________________

*/

!ifndef PCRELIB_INCLUDED
!define PCRELIB_INCLUDED

!define _PCRELIB_UN

!include LogicLib.nsh

# Macros

!macro RECheckPatternCall RESULT PATTERN
        Push `${PATTERN}`
        Call RECheckPattern
        Pop ${RESULT}
!macroend

!macro un.RECheckPatternCall RESULT PATTERN
        Push `${PATTERN}`
        Call un.RECheckPattern
        Pop ${RESULT}
!macroend

!macro REQuoteMetaCall RESULT SUBJECT
        Push `${SUBJECT}`
        Call REQuoteMeta
        Pop ${RESULT}
!macroend

!macro un.REQuoteMetaCall RESULT SUBJECT
        Push `${SUBJECT}`
        Call un.REQuoteMeta
        Pop ${RESULT}
!macroend

!macro REClearAllOptionsCall
        Call REClearAllOptions
!macroend

!macro un.REClearAllOptionsCall
        Call un.REClearAllOptions
!macroend

!macro REClearOptionCall OPTION
        Push `${OPTION}`
        Call REClearOption
!macroend

!macro un.REClearOptionCall OPTION
        Push `${OPTION}`
        Call un.REClearOption
!macroend

!macro RESetOptionCall OPTION
        Push `${OPTION}`
        Call RESetOption
!macroend

!macro un.RESetOptionCall OPTION
        Push `${OPTION}`
        Call un.RESetOption
!macroend

!macro REGetOptionCall RESULT OPTION
        Push `${OPTION}`
        Call REGetOption
        Pop ${RESULT}
!macroend

!macro un.REGetOptionCall RESULT OPTION
        Push `${OPTION}`
        Call un.REGetOption
        Pop ${RESULT}
!macroend

!macro REMatchesCall RESULT PATTERN SUBJECT PARTIAL
        Push `${PATTERN}`
        Push `${SUBJECT}`
        Push `${PARTIAL}`
        Push "0"
        Call REMatches
        Pop ${RESULT}
!macroend

!macro un.REMatchesCall RESULT PATTERN SUBJECT PARTIAL
        Push `${PATTERN}`
        Push `${SUBJECT}`
        Push `${PARTIAL}`
        Push "0"
        Call un.REMatches
        Pop ${RESULT}
!macroend

!macro RECaptureMatchesCall RESULT PATTERN SUBJECT PARTIAL
        Push `${PATTERN}`
        Push `${SUBJECT}`
        Push `${PARTIAL}`
        Push "1"
        Call REMatches
        Pop ${RESULT}
!macroend

!macro un.RECaptureMatchesCall RESULT PATTERN SUBJECT PARTIAL
        Push `${PATTERN}`
        Push `${SUBJECT}`
        Push `${PARTIAL}`
        Push "1"
        Call un.REMatches
        Pop ${RESULT}
!macroend

!macro REFindCall RESULT PATTERN SUBJECT
        Push `${PATTERN}`
        Push `${SUBJECT}`
        Call REFind
        Pop ${RESULT}
!macroend

!macro un.REFindCall RESULT PATTERN SUBJECT
        Push `${PATTERN}`
        Push `${SUBJECT}`
        Call un.REFind
        Pop ${RESULT}
!macroend

!macro REFindNextCall RESULT
        Call REFindNext
        Pop ${RESULT}
!macroend

!macro un.REFindNextCall RESULT
        Call un.REFindNext
        Pop ${RESULT}
!macroend

!macro REFindCloseCall
        Call REFindClose
!macroend

!macro un.REFindCloseCall
        Call un.REFindClose
!macroend

!macro REReplaceCall RESULT PATTERN SUBJECT REPLACEMENT REPLACEALL
        Push `${PATTERN}`
        Push `${SUBJECT}`
        Push `${REPLACEMENT}`
        Push `${REPLACEALL}`
        Call REReplace
        Pop ${RESULT}
!macroend

!macro un.REReplaceCall RESULT PATTERN SUBJECT REPLACEMENT REPLACEALL
        Push `${PATTERN}`
        Push `${SUBJECT}`
        Push `${REPLACEMENT}`
        Push `${REPLACEALL}`
        Call un.REReplace
        Pop ${RESULT}
!macroend

# Functions

!macro RECheckPattern
        !ifndef ${_PCRELIB_UN}RECheckPattern
                !define ${_PCRELIB_UN}RECheckPattern `!insertmacro ${_PCRELIB_UN}RECheckPatternCall`
                Function ${_PCRELIB_UN}RECheckPattern
                
                        Exch $0

                        NSISpcre::RECheckPattern /NOUNLOAD $0
                        
                        Pop $0
                        
                        Exch $0

                FunctionEnd
        !endif
!macroend

!macro REQuoteMeta
        !ifndef ${_PCRELIB_UN}REQuoteMeta
                !define ${_PCRELIB_UN}REQuoteMeta `!insertmacro ${_PCRELIB_UN}REQuoteMetaCall`
                Function ${_PCRELIB_UN}REQuoteMeta

                        Exch $0

                        NSISpcre::REQuoteMeta /NOUNLOAD $0

                        Pop $0

                        Exch $0

                FunctionEnd
        !endif
!macroend

!macro REClearAllOptions
        !ifndef ${_PCRELIB_UN}REClearAllOptions
                !define ${_PCRELIB_UN}REClearAllOptions `!insertmacro ${_PCRELIB_UN}REClearAllOptionsCall`
                Function ${_PCRELIB_UN}REClearAllOptions

                        NSISpcre::REClearAllOptions /NOUNLOAD

                FunctionEnd
        !endif
!macroend

!macro REClearOption
        !ifndef ${_PCRELIB_UN}REClearOption
                !define ${_PCRELIB_UN}REClearOption `!insertmacro ${_PCRELIB_UN}REClearOptionCall`
                Function ${_PCRELIB_UN}REClearOption

                        # [OPTION]
                        Exch $0

                        NSISpcre::REClearOption /NOUNLOAD $0

                        Pop $0

                FunctionEnd
        !endif
!macroend

!macro RESetOption
        !ifndef ${_PCRELIB_UN}RESetOption
                !define ${_PCRELIB_UN}RESetOption `!insertmacro ${_PCRELIB_UN}RESetOptionCall`
                Function ${_PCRELIB_UN}RESetOption
                
                        # [OPTION]
                        Exch $0
                        
                        NSISpcre::RESetOption /NOUNLOAD $0
                        
                        Pop $0
                
                FunctionEnd
        !endif
!macroend

!macro REGetOption
        !ifndef ${_PCRELIB_UN}REGetOption
                !define ${_PCRELIB_UN}REGetOption `!insertmacro ${_PCRELIB_UN}REGetOptionCall`
                Function ${_PCRELIB_UN}REGetOption
                
                        # [OPTION]
                        Exch $0

                        NSISpcre::REGetOption /NOUNLOAD $0
                        
                        Pop $0

                        Exch $0 # [RESULT]

                FunctionEnd
        !endif
!macroend

!macro REMatches
        !ifndef ${_PCRELIB_UN}REMatches
                !define ${_PCRELIB_UN}REMatches `!insertmacro ${_PCRELIB_UN}REMatchesCall`
                !define ${_PCRELIB_UN}RECaptureMatches `!insertmacro ${_PCRELIB_UN}RECaptureMatchesCall`
                Function ${_PCRELIB_UN}REMatches
                
                        # [PATTERN, SUBJECT, PARTIAL, CAPTURE]
                        Exch $0 # [PATTERN, SUBJECT, PARTIAL, $0]
                        Exch 3  # [$0, SUBJECT, PARTIAL, PATTERN]
                        Exch $1 # [$0, SUBJECT, PARTIAL, $1]
                        Exch 2  # [$0, $1, PARTIAL, SUBJECT]
                        Exch $2 # [$0, $1, PARTIAL, $2]
                        Exch    # [$0, $1, $2, PARTIAL]
                        Exch $3 # [$0, $1, $2, $3]
                        Push $4
                        
                        ${If} $0 != 0
                                StrCpy $4 5     # Push captured strings under the 5 items at the top of the stack
                        ${Else}
                                StrCpy $4 0     # Push captured strings to the top of the stack
                        ${EndIf}

                        NSISpcre::REMatches /NOUNLOAD $1 $2 $3 $4
                        Pop $1  # true, false or error
                        ClearErrors
                        ${If} $1 == "true"
                                Pop $1  # Number of captured patterns
                                ${If} $0 != 0
                                        # Capturing so leave captured strings on stack
                                        # Returned value is number of captured strings
                                ${Else}
                                        # Remove captured strings from the stack
                                        # Returned value is 'true'
                                        ${For} $2 1 $1
                                                Pop $3
                                        ${Next}
                                        StrCpy $1 "true"
                                ${EndIf}
                        ${ElseIf} $1 == "false"
                                # Do nothing - just return 'false'
                        ${Else}
                                SetErrors
                        ${EndIf}
                        
                        StrCpy $0 $1
                        
                        Pop $4
                        Pop $3
                        Pop $2
                        Pop $1
                        Exch $0
                        
                FunctionEnd
        !endif
!macroend

!macro REFind
        !ifndef ${_PCRELIB_UN}REFind
                !define ${_PCRELIB_UN}REFind `!insertmacro ${_PCRELIB_UN}REFindCall`
                Function ${_PCRELIB_UN}REFind

                        # [PATTERN, SUBJECT]
                        Exch $0 # [PATTERN, $0]
                        Exch    # [$0, PATTERN]
                        Exch $1 # [$0, $1]

                        NSISpcre::REFind /NOUNLOAD $1 $0 2
                        Pop $0  # true, false or error
                        ClearErrors
                        ${If} $0 == "true"
                                Pop $0  # Number of captured patterns
                                # Leave captured strings on stack
                                # Returned value is number of captured strings
                        ${ElseIf} $0 == "false"
                                # Do nothing - just return 'false'
                        ${Else}
                                SetErrors
                        ${EndIf}

                        Pop $1
                        Exch $0

                FunctionEnd
        !endif
        !ifndef ${_PCRELIB_UN}REFindClose
                !define ${_PCRELIB_UN}REFindClose `!insertmacro ${_PCRELIB_UN}REFindCloseCall`
                Function ${_PCRELIB_UN}REFindClose

                        NSISpcre::REFindClose /NOUNLOAD

                FunctionEnd
        !endif
!macroend

!macro REFindNext
        !ifndef ${_PCRELIB_UN}REFindNext
                !define ${_PCRELIB_UN}REFindNext `!insertmacro ${_PCRELIB_UN}REFindNextCall`
                Function ${_PCRELIB_UN}REFindNext
                
                        Push $0

                        NSISpcre::REFindNext /NOUNLOAD 1
                        Pop $0  # true, false or error
                        ClearErrors
                        ${If} $0 == "true"
                                Pop $0  # Number of captured patterns
                                # Leave captured strings on stack
                                # Returned value is number of captured strings
                        ${ElseIf} $0 == "false"
                                # Do nothing - just return 'false'
                        ${Else}
                                SetErrors
                        ${EndIf}

                        Exch $0

                FunctionEnd
        !endif
!macroend

!macro REReplace
        !ifndef ${_PCRELIB_UN}REReplace
                !define ${_PCRELIB_UN}REReplace `!insertmacro ${_PCRELIB_UN}REReplaceCall`
                Function ${_PCRELIB_UN}REReplace

                        # [PATTERN, SUBJECT, REPLACEMENT, REPLACEALL]
                        Exch $0 # [PATTERN, SUBJECT, REPLACEMENT, $0]
                        Exch 3  # [$0, SUBJECT, REPLACEMENT, PATTERN]
                        Exch $1 # [$0, SUBJECT, REPLACEMENT, $1]
                        Exch 2  # [$0, $1, REPLACEMENT, SUBJECT]
                        Exch $2 # [$0, $1, REPLACEMENT, $2]
                        Exch    # [$0, $1, $2, REPLACEMENT]
                        Exch $3 # [$0, $1, $2, $3]

                        NSISpcre::REReplace /NOUNLOAD $1 $2 $3 $0
                        Pop $1  # true, false or error
                        ClearErrors
                        ${If} $1 == "true"
                                Pop $0  # String with substitutions
                        ${ElseIf} $1 == "false"
                                StrCpy $0 ""
                        ${Else}
                                SetErrors
                                StrCpy $0 $1
                        ${EndIf}

                        Pop $3
                        Pop $2
                        Pop $1
                        Exch $0

                FunctionEnd
        !endif
!macroend

# LogicLib support (add =~ and !~ operators to LogicLib)
!macro _=~ _a _b _t _f
  !define _t=${_t}
  !ifdef _t=                                            ; If no true label then make one
    !define __t _LogicLib_Label_${__LINE__}
  !else
    !define __t ${_t}
  !endif

  Push $0
  ${REMatches} $0 ${_b} ${_a} 1
  StrCmp $0 "true" +1 +3
  Pop $0
  Goto ${__t}

  Pop $0
  !define _f=${_f}
  !ifndef _f=                                           ; If a false label then go there
    Goto ${_f}
  !endif
  !undef _f=${_f}

  !ifdef _t=                                            ; If we made our own true label then place it
    ${__t}:
  !endif
  !undef __t
  !undef _t=${_t}
!macroend

!macro _!~ _a _b _t _f
  !define _t=${_t}
  !ifdef _t=                                            ; If no true label then make one
    !define __t _LogicLib_Label_${__LINE__}
  !else
    !define __t ${_t}
  !endif

  Push $0
  !ifdef PCRELLUN
  ${un.REMatches} $0 ${_b} ${_a} 1
  !else
  ${REMatches} $0 ${_b} ${_a} 1
  !endif
  StrCmp $0 "true" +3 +1
  Pop $0
  Goto ${__t}

  Pop $0
  !define _f=${_f}
  !ifndef _f=                                           ; If a false label then go there
    Goto ${_f}
  !endif
  !undef _f=${_f}

  !ifdef _t=                                            ; If we made our own true label then place it
    ${__t}:
  !endif
  !undef __t
  !undef _t=${_t}
!macroend

# Uninstaller support

!macro un.RECheckPattern
	!ifndef un.RECheckPattern
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro RECheckPattern

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REQuoteMeta
	!ifndef un.REQuoteMeta
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REQuoteMeta

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REClearAllOptions
	!ifndef un.REClearAllOptions
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REClearAllOptions

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REClearOption
	!ifndef un.REClearOption
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REClearOption

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.RESetOption
	!ifndef un.RESetOption
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro RESetOption

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REGetOption
	!ifndef un.REGetOption
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REGetOption

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REMatches
	!ifndef un.REMatches
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REMatches

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.RECaptureMatches
	!ifndef un.RECaptureMatches
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro RECaptureMatches

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REFind
	!ifndef un.REFind
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REFind

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REFindNext
	!ifndef un.REFindNext
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REFindNext

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REFindClose
	!ifndef un.REFindClose
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REFindClose

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro un.REReplace
	!ifndef un.REReplace
		!undef _PCRELIB_UN
		!define _PCRELIB_UN `un.`

		!insertmacro REReplace

		!undef _PCRELIB_UN
		!define _PCRELIB_UN
	!endif
!macroend

!macro _un.=~ _a _b _t _f
        !define PCRELLUN
        !insertmacro _=~ `${_a}` `${_b}` `${_t}` `${_f}`
        !undef PCRELLUN
!macroend

!macro _un.!~ _a _b _t _f
        !define PCRELLUN
        !insertmacro _!~ `${_a}` `${_b}` `${_t}` `${_f}`
        !undef PCRELLUN
!macroend

!endif

