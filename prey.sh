#!/bin/bash

####################################################################
# Prey v0.1 - by Tomas Pollak (bootlog.org)
# URL : http://github.com/tomas/prey
# License: GPLv3
# Requisites: UUencode (sharutils), Sendmail or Mailx, Traceroute and Streamer (for webcam capture in Linux)
####################################################################

####################################################################
# configuracion primaria, necesaria para que funcione Prey
####################################################################

# url de verificacion, por defecto nada para que corra completo
url=''

# mail
emailtarget='mailbox@domain.com'

###################################################################
# encabezado del correo
####################################################################

from='no-reply@domain.com'
subject="Prey status report"

####################################################################
# configuracion secundaria, esto en teoria se puede modificar desde fuera
####################################################################

alertuser=0
killx=0

# transcurso de tiempo en que fueron modificados los archivos, en minutos
minutos=100

# de donde obtener el listado de archivos modificados. por defecto home
ruta_archivos=~/

# donde guardamos la imagen temporal
image_path=/tmp/prey.jpg

# backup ?
# backup_path=~/.prey

####################################################################
# ok, demosle. eso si veamos si estamos en Linux o Mac
####################################################################

platform=`uname`

if [ $platform == 'Darwin' ]; then
	getter='curl -s'
else
	getter='wget -q -O -'
fi

# en teoria se puede usar la variable OSTYPE de bash, pero no lo he probado
# posibles: Linux, Darwin, FreeBSD, CygWin?

####################################################################
# primero revisemos si buscamos url, y si existe o no
####################################################################
if [ -n "$url" ]; then
	echo 'Revisando URL...'

	# Mac OS viene con curl por defecto, asi que tenemos que checkear
	if [ $platform == 'Darwin' ]; then

		status=`curl -s -I $url | awk /HTTP/ | sed 's/[^200|302|400|404|500]//g'` # ni idea por que puse tantos status codes, deberia ser 200 o 400

		if [ $status == '200' ]; then
			config=`$getter $url`
		fi

#	elif [ $platform == 'Linux' ]; then
	else # ya agregaremos otras plataformas

		config=`$getter $url`

	fi

	# ok, ahora si el config tiene ALGO, significa que tenemos que hacer la pega
#	if [ "${status// /}" = "OK" ]; then
	if [ -n "$config" ]; then
		echo "HOLY SHIT!!"
	else
		echo 'Nada de que preocuparse'
		exit
	fi

fi

####################################################################
# partamos por ver cual es nuestro IP publico
####################################################################
echo "Obteniendo IP publico..."

publico=`$getter checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`

####################################################################
# ahora el IP interno
####################################################################
echo "Obteniendo IP privado..."

interno=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`

####################################################################
# gateway, mac e informacion de wifi (nombre red, canal, etc)
####################################################################
echo "Obteniendo enrutamiento interno y direccion MAC..."

if [ $platform == 'Darwin' ]; then
	routes=`netstat -rn | grep default | cut -c20-35`
	mac=`arp -n $routes | cut -f4 -d' '`
	# vaya a saber uno porque apple escondio tanto este archivo!
	wifi_info='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I'
else
	routes=`route -n`
	mac=`ifconfig | grep 'HWaddr' | cut -d: -f2-7`
#	wifi_info=`iwconfig ath0 | grep ESSID | cut -d\" -f2`
	wifi_info=`iwconfig 2>&1`
fi

####################################################################
# rastreemos la ruta completa hacia Google
####################################################################

traceroute=`which traceroute`
if [ -n "$traceroute" ]; then
	echo "Rastreando la ruta completa de acceso hacia la web..."
	complete_trace=`$traceroute -q1 www.google.com`
fi

####################################################################
# ahora veamos que archivos ha tocado el idiota
####################################################################
echo "Obteniendo listado de archivos modificados..."

# no incluimos los archivos carpetas ocultas ni los archivos weones de Mac OS
archivos=`find $ruta_archivos \( ! -regex '.*/\..*/..*' \) -type f -mmin -$minutos`
# archivos=`find ~/. \( ! -regex '.*/\..*/\.DS_Store' \) -type f -mmin -$minutos`

####################################################################
# ahora veamos que programas esta corriendo
####################################################################
echo "Obteniendo tiempo de uso y listado de programas en ejecucion..."

uptime=`uptime`
programas=`ps ux`

####################################################################
# ahora veamos a donde esta conectado
####################################################################
echo "Obteniendo listado de conexiones activas..."

connections=`netstat | grep -i established`

####################################################################
# ahora los metemos en el texto que va a ir en el mail
####################################################################
echo "Redactando el correo..."

texto="
Prey report!

Datos de conexion
--------------------------------------------------------------------
IP Publico: $publico. IP interno: $interno.

Enrutado de red (la primera)
--------------------------------------------------------------------
Direccion MAC: $mac. Gateway: $routes

Datos sobre red WiFi
--------------------------------------------------------------------
$wifi_info

En los ultimos $minutos minutos ha modificado los siguientes archivos
--------------------------------------------------------------------
$archivos

Ahora esta corriendo los siguientes programas
--------------------------------------------------------------------
$programas

Y tiene las siguientes conexiones abiertas
--------------------------------------------------------------------
$connections


Ahora a agarrar al maldito!

--
Con mucho carino,
El programa del que nunca quisiste recibir un mail, Prey. :)
"

####################################################################
# veamos si podemos sacar una foto del tipo con la camara del tarro.
# si no saquemos un pantallazo para ver que esta haciendo el idiota
####################################################################
echo "Obteniendo imagen para delatarlo..."

if [ $platform == 'Darwin' ]; then

	# muy bien, veamos si el tarro puede sacar una imagen con la webcam
	./isightcapture $image_path

else

	# probablemente esto lo usemos mas abajo
	import=`which import`

	# veamos si tenemos como sacar una imagen con la webcam
	streamer=`which streamer`
	if [ -n "$streamer" ]; then # excelente

		$streamer -o /tmp/imagen.jpeg &> /dev/null # streamer necesita que sea JPEG (con la E) para detectar el formato

		if [ -f '/tmp/imagen.jpeg' ]; then
			mv /tmp/imagen.jpeg $image_path
		else
			# TODO: aca estamos duplicando codigo que esta mas abajo, esto deberia ser una funcion
			if [ -n "$import" ]; then
				import -window root $image_path
			fi

		fi

	else # sacamos un pantallazo nomas

		if [ -n "$import" ]; then
			echo "No tenemos como sacar el pantallazo"
			# TODO: intentar con otro?
		else
			import -window root $image_path
		fi

	fi

fi

echo "Foto sacada!"

####################################################################
# La comprimimos?
####################################################################
# echo "Comprimiento imagen..."
# tar zcf $image_path.tar.gz $image_path
# image_path=$image_path.tar.gz

####################################################################
# ahora la estocada final: mandemos el mail
####################################################################
echo "Enviando el correo..."

CONTENT=$texto
msgdate=`date +"%a, %e %Y %T %z"`
boundary=GvXjxJ+pjyke8COw
archdate=`date +%F`
attachment=`basename "$image_path"`
archattachment="${archdate}-${attachment}"
mimetype=`file -i $image_path | awk '{ print $2 }'`

daemail=$(cat <<!
Date: $msgdate
From: $from
To: $emailtarget
Subject: $subject @ $msgdate
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary="$boundary"
Content-Disposition: inline

--$boundary
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline

$CONTENT

--$boundary
Content-Type: $mimetype; name="$attachment"
Content-Disposition: attachment; filename="$attachment"
Content-Transfer-Encoding: base64

!)

echo "$daemail" > msg.tmp
echo  >> msg.tmp
if [ "$attachment" = "text/plain" ]; then
        cat "$image_path" >> msg.tmp
else
        uuencode -m $image_path $attachment | sed '1d' >> msg.tmp
fi

echo  >> msg.tmp
echo "--$boundary--" >> msg.tmp
email=`cat msg.tmp`

sendmail=`which sendmail`
mailx=`which mailx`
if [ -n "$sendmail" ]; then
	echo "$email" | $sendmail -t
elif [ -n "$mailx" ]; then
	$mailx -n -s "$subject @ $msgdate" $emailtarget < msg.tmp
# mailx through SMTP (gmail) --> puede ser una opcion si el servidor de la casilla llega a alegar por envio de spam
# env MAILRC=/dev/null from=sending_account@gmail.com smtp=smtp.gmail.com smtp-auth-user=sending_account smtp-use-starttls=yes smtp-auth-password=password smtp-auth=login mailx -n -s "subject" some_other_account@gmail(or_some_else).com </root/test.txt
fi

####################################################################
# ok, todo bien. ahora limpiemos la custion
####################################################################
echo "Eliminando la evidencia..."

rm msg.tmp
rm $image_path

####################################################################
# le avisamos al ladron que esta cagado?
####################################################################

if [ $alertuser == 1 ]; then

	# veamos si estamos en GNOME
	gnome=`ps x | grep `ps o ppid,fname | grep bash | grep -v grep | head -1 | awk '{print $1}'` | grep 'gnome-session' | wc -l`

	if [ $gnome == 1 ]; then

		# veamos si tenemos zenity
		type 'zenity' > /dev/null 2>&1

		if [ $? -gt 0 ]; then

			echo "No tenemos como mostrarle el mensaje"
			# TODO: intentar con otro?

		else

			# lo agarramos pal weveo ?
			# zenity --question --text "Este computador es tuyo?"
			# if [ $? = 0 ]; then
				# TODO: inventar buena talla
			# fi

			# progress bar, en caso de que queramos usarlo
			# find ~ -name '*.ps' | zenity --progress --pulsate

			 # mensaje de informacion
			# zenity --info --text "Obtenimos la informacion"

			 # mejor, mensaje de error!
			zenity --error --text "Te pillé maldito."

		fi

	fi

fi

echo "...todo listo!"

####################################################################
# reiniciamos X para wevearlo mas aun?
####################################################################
if [ $killx == 1 ]; then

	echo "Botandolo del servidor grafico!"
	killall gdm

fi
