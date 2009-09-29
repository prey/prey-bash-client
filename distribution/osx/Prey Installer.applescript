on ReplaceText(find, replace, subject)
	set prevTIDs to text item delimiters of AppleScript
	set text item delimiters of AppleScript to find
	set subject to text items of subject
	set text item delimiters of AppleScript to replace
	set subject to "" & subject
	set text item delimiters of AppleScript to prevTIDs
	return subject
end ReplaceText
global selectedmethod
on clicked theObject
	if (name of theObject = "wsselected") then
		set selectedmethod to true
	else if (name of theObject = "emailselect") then
		set selectedmethod to false
	else if (name of theObject = "nextmethod") then
		tell tab view "tabsis" of window "Prey 0.3"
			set current tab view item to tab view item "general"
		end tell
	else if (name of theObject = "nextgeneral") then
		try
			set tmpVar to selectedmethod
		on error
			set selectedmethod to true
		end try
		if (selectedmethod is false) then
			tell tab view "tabsis" of window "Prey 0.3"
				set current tab view item to tab view item "mailconfig"
			end tell
		else
			tell tab view "tabsis" of window "Prey 0.3"
				set current tab view item to tab view item "wslogin"
			end tell
		end if
	else if (name of theObject = "runinstall") then
		(* Comienza instalacion *)
		set apth to (path to current application as Unicode text)
		set apth to ReplaceText(":", "/", apth)
		set apth to ReplaceText(" ", "\\ ", apth)
		set apth to "/Volumes/" & apth & "Contents/Resources/"
		do shell script "cd " & apth & "
		sudo rm -Rf /usr/share/prey
		sudo mkdir /tmp/prey
		sudo cp config /tmp/prey/temp_config
		sudo unzip -u prey.zip -d /usr/share/prey
		" with administrator privileges
		set idioma to contents of combo box "idioma" of tab view item "general" of tab view "tabsis" of window "Prey 0.3"
		if (idioma = "Inglés" or idioma = "English") then
			set idioma to "en"
		else
			set idioma to "es"
		end if
		set frecuencia to contents of combo box "frecuencia" of tab view item "general" of tab view "tabsis" of window "Prey 0.3"
		if (selectedmethod is true) then
			set wsapikey to contents of text field "apikey" of tab view item "wslogin" of tab view "tabsis" of window "Prey 0.3"
			set wsdevicekey to contents of text field "devicekey" of tab view item "wslogin" of tab view "tabsis" of window "Prey 0.3"
			do shell script "
			cd /tmp/prey
			sed -i -e \"s/lang='.*'/lang='" & idioma & "'/\" temp_config
			sed -i -e \"s/api_key='.*'/api_key='" & wsapikey & "'/\" temp_config
			sed -i -e \"s/device_key='.*'/device_key='" & wsdevicekey & "'/\" temp_config" with administrator privileges
		else if (selectedmethod is false) then
			set email to contents of text field "email" of tab view item "mailconfig" of tab view "tabsis" of window "Prey 0.3"
			set smtpuser to contents of text field "smtpuser" of tab view item "mailconfig" of tab view "tabsis" of window "Prey 0.3"
			set smtpserver to contents of text field "smtpserver" of tab view item "mailconfig" of tab view "tabsis" of window "Prey 0.3"
			set smtppass to contents of text field "smtppass" of tab view item "mailconfig" of tab view "tabsis" of window "Prey 0.3"
			set checkivi to contents of text field "checkivi" of tab view item "mailconfig" of tab view "tabsis" of window "Prey 0.3"
			set checkivi to ReplaceText("/", "\\/", checkivi)
			do shell script "
			cd /tmp/prey
			sed -i -e \"s/post_method='.*'/post_method='email'/\" temp_config
			sed -i -e \"s/lang='.*'/lang='" & idioma & "'/\" temp_config
			sed -i -e \"s/mail_to='.*'/mail_to='" & email & "'/\" temp_config
			sed -i -e \"s/check_url='.*'/check_url='" & checkivi & "'/\" temp_config
			sed -i -e \"s/smtp_server='.*'/smtp_server='" & smtpserver & "'/\" temp_config
			sed -i -e \"s/smtp_username='.*'/smtp_username='" & smtpuser & "'/\" temp_config
			sed -i -e \"s/smtp_password='.*'/smtp_password='" & smtppass & "'/\" temp_config" with administrator privileges
		end if
		do shell script "
		cd /tmp/prey
		sudo cp temp_config /usr/share/prey/config
		rm -r /tmp/prey
		(sudo crontab -l | grep -v prey; echo \"*/" & frecuencia & " * * * * /usr/share/prey/prey.sh > /dev/null \") | sudo crontab -" with administrator privileges
		(* Instalacion Ended*)
		tell tab view "tabsis" of window "Prey 0.3"
			set current tab view item to tab view item "finish"
		end tell
	else if (name of theObject = "quitprey") then
		tell current application to quit
	end if
end clicked
on choose menu item theObject
	if title of theObject = "Acerca de Prey Installer" then
		load nib "creditos"
	end if
end choose menu item
(*Lineas inutiles *)
on bounds changed theObject
end bounds changed
on end editing theObject
end end editing
on action theObject
end action
on awake from nib theObject
end awake from nib
on clicked toolbar item theObject
end clicked toolbar item
(*Fin lineas dummy.*)