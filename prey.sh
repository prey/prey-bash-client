#!/bin/bash
####################################################################
# PREY - by Tomas Pollak (bootlog.org)
# URL : http://prey.bootlog.org
# License: GPLv3
####################################################################

version='0.2'
. ./testconfig

####################################################################
# ok, demosle. eso si veamos si estamos en Linux o Mac
####################################################################
echo -e "\n ### PREY $version spreads its wings!\n"

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
	# eventualmente el archivo remoto puede tener parametros y gatillar comportamientos
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
	wifi_info=`iwconfig 2>&1 | grep -v "no wireless"`
fi

if [ ! -n "$wifi_info" ]; then # no wifi connection, let's see if we can auto connect to one

	if [ $platform == 'Linux' ]; then

		# Find device used for wifi.
		devlist=$(cat /proc/net/wireless | tail --lines=1) 2>/dev/null
		devleft=${devlist#' '*}
		devright=${devlist%%':'*}
		echo $devright | grep "" > /tmp/dev_pure
		dev=$(cat /tmp/dev_pure)

		# Get a list of open wifi points, and choose one
		iwlist $dev scan > /tmp/scan_output 2>/dev/null
		scanone=$(egrep 'ESSID|Encryption' /tmp/scan_output)
		essidone=${scanone%%"Encryption key:off"*}
		essidquot=${essidone##*'ESSID:"'}
		essid=${essidquot%'"'*}

		# Connect
		if [[ ! -z $essid && ! -z $dev ]]; then
			iwconfig $dev essid $essid
			wifi_info=`iwconfig 2>&1 | grep -v "no wireless"`
		fi

	else # untested, for mac

		networksetup -setnetworkserviceenabled AirPort off
		networksetup -setnetworkserviceenabled AirPort on
		wifi_info=`/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I`

	fi

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

connections=`netstat -taue | grep -i established`

####################################################################
# ahora los metemos en el texto que va a ir en el mail
####################################################################
echo " -- Redactando el correo..."
. lang/$lang

####################################################################
# veamos si podemos sacar una foto del tipo con la camara del tarro.
# de todas formas un pantallazo para ver que esta haciendo el idiota
####################################################################
echo " -- Obteniendo un pantallazo y una foto del impostor..."

if [ $platform == 'Darwin' ]; then

	screencapture='/usr/sbin/screencapture -mx'

	if [ `whoami` == 'root' ]; then # we need to get the PID of the loginwindow and take the screenshot through launchctl

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

emailstatus=`./sendEmail -f "$from" -t "$emailtarget" -u "$complete_subject" -s $smtp_server -a $picture $screenshot -o message-file=msg.tmp tls=auto username=$smtp_username password=$smtp_password`

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
# TODO: esto solo funciona con Linux (KDE y GNOME, y quizas XFCE)
####################################################################

if [ $alertuser == 'y' ]; then

	if [ $platform == 'Linux' ]; then

		# veamos si tenemos zenity o kdialog
		zenity=`which zenity`
		kdialog=`which kdialog`

		if [ -n "$zenity" ]; then

			# lo agarramos pal weveo ?
			# zenity --question --text "Este computador es tuyo?"
			# if [ $? = 0 ]; then
				# TODO: inventar buena talla
			# fi

			 # mensaje de informacion
			# zenity --info --text "Obtuvimos la informacion"

			 # mejor, mensaje de error!
			$zenity --error --text $alertmsg

		elif [ -n "$kdialog" ]; then #untested!

			$kdialog --error $alertmsg

		fi

	fi

fi

####################################################################
# reiniciamos X para wevearlo mas aun?
####################################################################
if [ $killx == 1 ]; then # muahahaha

	echo " -- Botandolo del servidor grafico!"

	# ahora validamos por GDM, KDM, XDM y Entrance, pero hay MUCHO codigo repetido. TODO: reducir!
	if [ $platform == 'Linux' ]; then
		pkill "gdm|kdm|xdm|entrance"
	else
		echo " !! Como lo botamos desde Mac OS?"
	fi

fi

####################################################################
# this is the end, my only friend
####################################################################
echo -e " -- ...todo listo!\n"
