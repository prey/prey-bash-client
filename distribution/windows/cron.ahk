; Prey Runner Script
; By Newstart and Tomas Pollak
; http://preyproject.com

#Persistent
#NoTrayIcon
#SingleInstance force
RegRead, PreyPath, HKEY_LOCAL_MACHINE, SOFTWARE\Prey, Path
MinDelay = 120000 ; two minutes
ExecutionDelay = 1200000 ; twenty minutes
Log_to = ;
Test = ;

Loop, %0% { ; for each command line parameter
	If (%A_Index% = "--log")
		Log_to = > %PreyPath%/prey.log
	Else If (%A_Index% = "--test")
		Test = -t ;
}

Loop
{
	RunWait, %comspec% /c %PreyPath%\bin\bash.exe %PreyPath%\prey.sh %Test% %Log_to%, %PreyPath%, hide
	RegRead, setDelay, HKEY_LOCAL_MACHINE, SOFTWARE\Prey, Delay
	if (not ErrorLevel and setDelay > MinDelay)
	{
		ExecutionDelay = %setDelay%
		; FileAppend, "Prey now running every %ExecutionDelay% miliseconds.`n", %PreyPath%\prey.log
		setDelay =  ; Free the memory.
	}
	Sleep %ExecutionDelay%
}
return
