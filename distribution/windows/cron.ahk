; Prey Runner Script
; By Newstart and Tomas Pollak
; http://preyproject.com

#Persistent
#NoTrayIcon
#SingleInstance force
PreyPath = c:\Prey
MinDelay = 120000 ; two minutes
ExecutionDelay = 1200000 ; twenty minutes
Loop
{
	RunWait, %comspec% /c %PreyPath%\bin\bash.exe %PreyPath%\prey.sh > %PreyPath%/prey.log, %PreyPath%, hide
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
