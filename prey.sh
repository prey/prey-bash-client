#!/bin/bash

####################################################################
# Prey v0.1 - by Tomas Pollak (bootlog.org)
# URL : http://github.com/tomas/prey
# License: GPLv3
# Requisites for Linux: Wget, Traceroute, Scrot, Streamer (for webcam capture) and Perl Libs IO::Socket::SSL and NET::SSLeay (yeah, i know)
####################################################################

####################################################################
# configuracion primaria, necesaria para que funcione Prey
####################################################################

# url de verificacion, por defecto nada para que corra completo
url=''

# mail
emailtarget='mailbox@domain.com'

# configuracion smtp, no podemos mandarlo con sendmail/mailx porque rebota como spam
smtp_server='smtp.gmail.com:587'
smtp_username='username@gmail.com'
smtp_password='password'

# esto se puede dejar tal cual, pero cambialo si quieres
from='Prey <no-reply@gmail.com>'
subject="PREY -- status report"

####################################################################
# configuracion secundaria, esto en teoria se podra modificar desde fuera
####################################################################

alertuser=0
killx=0

# transcurso de tiempo en que fueron modificados los archivos, en minutos
minutos=100

# de donde obtener el listado de archivos modificados. por defecto home
ruta_archivos=~/

# donde guardamos la imagen temporal
screenshot=/tmp/prey-screenshot.jpg
picture=/tmp/prey-picture.jpg

# backup ?
# backup_path=~/.prey

####################################################################
# ok, demosle. eso si veamos si estamos en Linux o Mac
####################################################################
echo -e '\n ### Prey 0.1 al acecho!\n'

platform=`uname`
logged_user=`who | cut -d' ' -f1 | sort -u | tail -1`

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
	echo ' -- Revisando URL...'

	# Mac OS viene con curl por defecto, asi que tenemos que checkear
	if [ $platform == 'Darwin' ]; then

		status=`$getter -I $url | awk /HTTP/ | sed 's/[^200|302|400|404|500]//g'` # ni idea por que puse tantos status codes, deberia ser 200 o 400

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
		echo " -- HOLY GUACAMOLE!!"
	else
		echo -e " -- Nada de que preocuparse. :)\n"
		exit
	fi

fi

####################################################################
# partamos por ver cual es nuestro IP publico
####################################################################
echo " -- Obteniendo IP publico..."

publico=`$getter checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`

####################################################################
# ahora el IP interno
####################################################################
echo " -- Obteniendo IP privado..."

# works in mac as well as linux (linux just prints an extra "addr:")
interno=`ifconfig | grep "inet " | grep -v "127.0.0.1" | cut -f2 | awk '{ print $2}'`

####################################################################
# gateway, mac e informacion de wifi (nombre red, canal, etc)
####################################################################
echo " -- Obteniendo enrutamiento interno y direccion MAC..."

if [ $platform == 'Darwin' ]; then
	routes=`netstat -rn | grep default | cut -c20-35`
	mac=`arp -n $routes | cut -f4 -d' '`
	# vaya a saber uno porque apple escondio tanto este archivo!
	wifi_info=`/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I`
else
	routes=`route -n`
	mac=`ifconfig | grep 'HWaddr' | cut -d: -f2-7`
#	wifi_info=`iwconfig ath0 | grep ESSID | cut -d\" -f2`
	wifi_info=`iwconfig 2>&1`
fi

####################################################################
# rastreemos la ruta completa hacia Google
####################################################################

# disabled for now, TOO SLOW!
# traceroute=`which traceroute`
if [ -n "$traceroute" ]; then
	echo " -- Rastreando la ruta completa de acceso hacia la web..."
	complete_trace=`$traceroute -q1 www.google.com 2>&1`
fi

####################################################################
# ahora veamos que archivos ha tocado el idiota
####################################################################
echo " -- Obteniendo listado de archivos modificados..."

# no incluimos los archivos carpetas ocultas ni los archivos weones de Mac OS
archivos=`find $ruta_archivos \( ! -regex '.*/\..*/..*' \) -type f -mmin -$minutos`
# archivos=`find ~/. \( ! -regex '.*/\..*/\.DS_Store' \) -type f -mmin -$minutos`

####################################################################
# ahora veamos que programas esta corriendo
####################################################################
echo " -- Obteniendo tiempo de uso y listado de programas en ejecucion..."

uptime=`uptime`
programas=`ps ux`

####################################################################
# ahora veamos a donde esta conectado
####################################################################
echo " -- Obteniendo listado de conexiones activas..."

connections=`netstat | grep -i established`

####################################################################
# ahora los metemos en el texto que va a ir en el mail
####################################################################
echo " -- Redactando el correo..."

texto="
Buenas noticias amigo mio... al parecer lo encontramos!

Status general del computador (uptime)
--------------------------------------------------------------------
$uptime

Datos de conexion
--------------------------------------------------------------------
IP Publico: $publico. IP interno: $interno.

Enrutado de red
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
Tu fiel servidor, Prey
Para actualizaciones visita http://prey.bootlog.org
"

####################################################################
# veamos si podemos sacar una foto del tipo con la camara del tarro.
# de todas formas un pantallazo para ver que esta haciendo el idiota
####################################################################
echo " -- Obteniendo un pantallazo y una foto del impostor..."

if [ $platform == 'Darwin' ]; then

	screencapture='/usr/sbin/screencapture -mx'

	if [`whoami` == 'root']; then # we need to get the PID of the loginwindow and take the screenshot through launchctl

        loginpid=`ps -ax | grep loginwindow.app | grep -v grep | awk '{print $1}'`
        launchctl bsexec $loginpid $screencapture $screenshot

	else

		$screencapture $screnshot

	fi

	# muy bien, veamos si el tarro puede sacar una imagen con la webcam
	./isightcapture $picture

else

	# si tenemos streamer, saquemos la foto
	streamer=`which streamer`
	if [ -n "$streamer" ]; then # excelente

		$streamer -o /tmp/imagen.jpeg &> /dev/null # streamer necesita que sea JPEG (con la E) para detectar el formato

		if [ -e '/tmp/imagen.jpeg' ]; then

			mv /tmp/imagen.jpeg $picture

		else # by Vanscot, http://www.hometown.cl/ --> some webcams are unable to take JPGs so we grab a PPM

			$streamer -o /tmp/imagen.ppm &> /dev/null
			if [ -e '/tmp/imagen.ppm' ]; then

				$convert=`which convert`
				if [ -n "$convert" ]; then # si tenemos imagemagick instalado podemos convertirla a JPG
					$convert /tmp/imagen.ppm $picture > /dev/null
				else # trataremos de enviarla asi nomas
					picture='/tmp/imagen.ppm'
				fi

			fi

		fi

	fi

	scrot=`which scrot` # scrot es mas liviano y mas rapido
	import=`which import` # viene con imagemagick, mas obeso

	if [ -n "$scrot" ]; then

		if [ `whoami` == 'root' ]; then
			DISPLAY=:0 su $logged_user -c "$scrot $screenshot"
		else
			$scrot $screenshot
		fi

	elif [ -n "$import" ]; then

		args="-window root -display :0"

		if [ `whoami` == 'root' ]; then # friggin su command, cannot pass args with "-" since it gets confused
			su $logged_user -c "$import $args $screenshot"
		else
			$import $args $screenshot
		fi

	fi

fi

echo " -- Imagenes listas!"

####################################################################
# Las comprimimos?
####################################################################
# echo "Comprimiento imagen..."
# tar zcf $image_path.tar.gz $image_path
# image_path=$image_path.tar.gz

####################################################################
# ahora la estocada final: mandemos el mail
####################################################################
echo " -- Enviando el correo..."
complete_subject="$subject @ `date +"%a, %e %Y %T %z"`"
echo "$texto" > msg.tmp

# si no pudimos sacar el pantallazo o la foto, limpiamos las variables
if [ ! -e "$picture" ]; then
	picture=''
fi

if [ ! -e "$screenshot" ]; then
	screenshot=''
fi

emailstatus=`./sendEmail -f $from -t $emailtarget -u "$complete_subject" -s $smtp_server -a $picture $screenshot -o message-file=msg.tmp tls=auto username=$smtp_username password=$smtp_password`

if [[ "$emailstatus" =~ "ERROR" ]]; then
	echo ' !! Hubo un problema enviando el correo. Estan bien puestos los datos?'
fi

####################################################################
# ok, todo bien. ahora limpiemos la custion
####################################################################
echo " -- Eliminando la evidencia..."

if [ -e "$picture" ]; then
	rm $picture
fi
if [ -e "$screenshot" ]; then
	rm $screenshot
fi
rm msg.tmp

####################################################################
# le avisamos al ladron que esta cagado?
# TODO: esto solo funciona con Zenity (GNOME y creo que XFCE)
####################################################################

if [ $alertuser == 1 ]; then

	# veamos si tenemos zenity
	zenity=`which zenity`

	if [ -n "$zenity" ]; then

		echo " -- No tenemos como mostrarle el mensaje"
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
		$zenity --error --text "Te pillé maldito."

	fi

fi

####################################################################
# reiniciamos X para wevearlo mas aun?
####################################################################
if [ $killx == 1 ]; then # muahahaha

	echo " -- Botandolo del servidor grafico!"

	# ahora validamos por GDM, KDM, XDM y Entrance, pero hay MUCHO codigo repetido. TODO: reducir!

	if [ `ps aux | grep gdm | grep -v grep | wc -l` -gt 0 ]; then

		killall gdm

	elif [ `ps aux | grep kdm | grep -v grep | wc -l` -gt 0]; then

		killall kdm

	elif [ `ps aux | grep xdm | grep -v grep | wc -l` -gt 0]; then

		killall xdm

	elif [ `ps aux | grep entrance | grep -v grep | wc -l` -gt 0]; then

		killall entrance

	fi

fi

####################################################################
# this is the end, my only friend
####################################################################
echo -e " -- ...todo listo!\n"
