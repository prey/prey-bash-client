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
	Run, %comspec% /c %PreyPath%\bin\bash.exe %PreyPath%\prey.sh >> %PreyPath%/prey.log, %PreyPath%, hide
	IFExist, %PreyPath%\delay.tmp
	{
		FileRead, Contents, %PreyPath%\delay.tmp
		if (not ErrorLevel and Contents > MinDelay)
		{
			ExecutionDelay = %Contents%
			Contents =  ; Free the memory.
		}
		FileMove, %PreyPath%\delay.tmp, %PreyPath%\delay
	}
	Sleep %ExecutionDelay%
}
return
