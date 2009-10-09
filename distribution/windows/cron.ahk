; Prey Runner Script
; By Newstart and Tomas Pollak
; http://preyproject.com

#Persistent
#NoTrayIcon
#SingleInstance force
PreyPath = c:\Prey
MinDelay = 120000 ; two minutes
Loop
{
	FileRead, ExecutionDelay, %PreyPath%\delay
	if (ErrorLevel or ExecutionDelay < MinDelay) ; file not found or empty?
	{
		ExecutionDelay = %MinDelay% 
		; FileDelete, %PreyPath%\delay
		; FileAppend, %ExecutionDelay%, %PreyPath%\delay
	}
	Sleep %ExecutionDelay%
	ExecutionDelay =  ; Free the memory.
	Run, %PreyPath%\bin\bash.exe "%PreyPath%\prey.sh", %PreyPath%, hide
}
return
