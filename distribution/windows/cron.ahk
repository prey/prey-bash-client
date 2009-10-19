; Prey Runner Script
; By Newstart and Tomas Pollak
; http://preyproject.com

#Persistent
#NoTrayIcon
#SingleInstance force
PreyPath = c:\Prey
MinDelay = 120000 ; two minutes
ExecutionDelay = 1200000 ; twenty minutes
Log_to = ;
Test = ;

Loop, %0% { ; for each command line parameter
	If (%A_Index% = "--log")
		Log_to = "> %PreyPath%/prey.log"
	Else If (%A_Index% = "--test")
		Test = -t ;
}

Loop
{
	RunWait, %comspec% /c %PreyPath%\bin\bash.exe %PreyPath%\prey.sh %Test% %Log_to%, %PreyPath%, hide
	FileRead, Contents, %PreyPath%\delay
	if (not ErrorLevel and Contents > MinDelay)
	{
		ExecutionDelay = %Contents%
		; FileAppend, "Prey now running every %ExecutionDelay% miliseconds.`n", %PreyPath%\prey.log
		Contents =  ; Free the memory.
	}
	Sleep %ExecutionDelay%
}
return
