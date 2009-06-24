on ReplaceText(find, replace, subject)
	set prevTIDs to text item delimiters of AppleScript
	set text item delimiters of AppleScript to find
	set subject to text items of subject
	set text item delimiters of AppleScript to replace
	set subject to "" & subject
	set text item delimiters of AppleScript to prevTIDs
	return subject
end ReplaceText
on clicked theObject
	if (title of theObject = "Instalar" or title of theObject = "Install") then
		set apth to (path to current application as Unicode text)
		set apth to ReplaceText(":", "/", apth)
		set apth to ReplaceText(" ", "\\ ", apth)
		set apth to "/Volumes/" & apth & "Contents/Resources/"
		set idioma to contents of combo box "idioma" of tab view item "General" of tab view "tabsis" of window "Prey 0.2"
		set directorio to contents of text field "directorio" of tab view item "General" of tab view "tabsis" of window "Prey 0.2"
		set email to contents of text field "email" of tab view item "General" of tab view "tabsis" of window "Prey 0.2"
		set smtpuser to contents of text field "smtpuser" of tab view item "Avanzado" of tab view "tabsis" of window "Prey 0.2"
		set smtpserver to contents of text field "smtpserver" of tab view item "Avanzado" of tab view "tabsis" of window "Prey 0.2"
		set smtppass to contents of text field "smtppass" of tab view item "Avanzado" of tab view "tabsis" of window "Prey 0.2"
		set checkivi to contents of text field "checkivi" of tab view item "General" of tab view "tabsis" of window "Prey 0.2"
		set checkivi to ReplaceText("/", "\\/", checkivi)
		set frecuencia to contents of combo box "frecuencia" of tab view item "General" of tab view "tabsis" of window "Prey 0.2"
		set myCount to (count every word of email)
		set error_data to false
		set isEmail to (email contains "@" and myCount > 2)
		if email is equal to "nombre@dominio.com" then
			display dialog "Falta el correo | Email Missing" buttons {"OK"}
			set error_data to true
		else if isEmail is false then
			display dialog "Falta el correo | Email Missing" buttons {"OK"}
			set error_data to true
		end if
		if (smtppass = "" or smtpuser = "" or smtpserver = "") then
			display dialog "Faltan Datos para envio de Correo" buttons {"Volver"}
			set error_data to true
		end if
		if (idioma = "Inglés" or idioma = "English") then
			set idioma to "en"
		else
			set idioma to "es"
		end if
		if error_data is false then
			close window "Prey 0.2"
			do shell script "sudo mkdir -p " & directorio & "
			cd " & directorio & "
			sudo mkdir lang
			sudo mkdir alerts
			sudo mkdir platform
			cd " & apth & "
			sudo mkdir /tmp/prey
			config_file=config
			temp_config_file=temp_config
			sudo cp $config_file /tmp/prey/$temp_config_file
			cd /tmp/prey
			sed -i -e \"s/lang='.*'/lang='" & idioma & "'/\" $temp_config_file
			sed -i -e \"s/emailtarget='.*'/emailtarget='" & email & "'/\" $temp_config_file
			sed -i -e \"s/url='.*'/url='" & checkivi & "'/\" $temp_config_file
			sed -i -e \"s/smtp_server='.*'/smtp_server='" & smtpserver & "'/\" $temp_config_file
			sed -i -e \"s/smtp_username='.*'/smtp_username='" & smtpuser & "'/\" $temp_config_file
			sed -i -e \"s/smtp_password='.*'/smtp_password='" & smtppass & "'/\" $temp_config_file
			sudo cp $temp_config_file " & directorio & "/$config_file
			cd " & apth & "
			sudo cp isightcapture " & directorio & " sudo cp -f prey.sh sendEmail " & directorio & "
			sudo cp -f en es " & directorio & "/lang
			sudo cp -f base darwin " & directorio & "/platform
			sudo cp -f prey-wallpaper-en.png prey-wallpaper-es.png " & directorio & "/alerts
			sudo chmod +x " & directorio & "/sendEmail " & directorio & "/prey.sh " & directorio & "/isightcapture " & directorio & "/lang/es " & directorio & "/lang/en " & directorio & "/platform/base " & directorio & "/platform/darwin
			sudo chmod 700 " & directorio & "/$config_file
			rm -r /tmp/prey
			(sudo crontab -l | grep -v prey; echo \"*/" & frecuencia & " * * * * cd " & directorio & "; ./prey.sh\") | sudo crontab -" with administrator privileges
			tell current application to quit
		end if
	else if (title of theObject = "Siguiente Paso" or title of theObject = "Next Step") then
		tell tab view "tabsis" of window "Prey 0.2"
			set current tab view item to tab view item "Avanzado"
		end tell
	else if (title of theObject = "Back" or title of theObject = "Atras") then
		tell tab view "tabsis" of window "Prey 0.2"
			set current tab view item to tab view item "General"
		end tell
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