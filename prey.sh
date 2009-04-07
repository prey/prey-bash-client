#!/bin/bash
####################################################################
# PREY - by Tomas Pollak (bootlog.org)
# URL : http://prey.bootlog.org
# License: GPLv3
####################################################################

version='0.2'
. ./config
. lang/$lang

####################################################################
# ok, demosle. eso si veamos si estamos en Linux o Mac
####################################################################
echo -e $STRING_START

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
	echo $STRING_CHECK_URL

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
		echo $STRING_PROBLEM
	else
		echo -e $STRING_NO_PROBLEM
		exit
	fi

fi

####################################################################
# partamos por ver cual es nuestro IP publico
####################################################################
echo $STRING_GET_IP

publico=`$getter checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`

####################################################################
# ahora el IP interno
####################################################################
echo $STRING_GET_LAN_IP

# works in mac as well as linux (linux just prints an extra "addr:")
interno=`ifconfig | grep "inet " | grep -v "127.0.0.1" | cut -f2 | awk '{ print $2}'`

####################################################################
# gateway, mac e informacion de wifi (nombre red, canal, etc)
####################################################################
echo $STRING_GET_MAC_AND_WIFI

if [ $platform == 'Darwin' ]; then
	airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
	routes=`netstat -rn | grep default | cut -c20-35`
	mac=`arp -n $routes | cut -f4 -d' '`
	wifi_info=`$airport -I`
else
	routes=`route -n`
	mac=`ifconfig | grep 'HWaddr' | cut -d: -f2-7`
	wifi_info=`iwconfig 2>&1 | grep -v "no wireless"`
fi

if [ ! -n "$wifi_info" ]; then # no wifi connection, let's see if we can auto connect to one

	echo $STRING_TRY_TO_CONNECT

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

		# lets see if we have a valid device and essid
		if [[ ! -z $essid && ! -z $dev ]]; then
			iwconfig $dev essid $essid
			wifi_info=`iwconfig 2>&1 | grep -v "no wireless"`
		else
			echo $STRING_NO_CONNECT_TO_WIFI
		fi

	else # Mac Wifi Autoconnect by Warorface <warorface@gmail.com>

		# restart airport service
		networksetup -setnetworkserviceenabled AirPort off 2>/dev/null
		networksetup -setnetworkserviceenabled AirPort on 2>/dev/null

		# power on the airport
		networksetup -setairportpower off 2>/dev/null
		networksetup -setairportpower on 2>/dev/null

		# list available access points and parse to get first SSID with security "NONE"
		essid=`$airport -s | grep NONE | head -1 | cut -c1-33 | sed 's/^[ \t]*//'`

		if [ -n "$essid" ]; then

			# now lets connect and get the new info
			networksetup -setairportnetwork $essid 2>/dev/null
			wifi_info=`$airport -I`

		else

			echo " -- Couldn't find a way to connect to an open wifi network!"

		fi

	fi

fi

####################################################################
# rastreemos la ruta completa hacia Google
####################################################################

# disabled for now, TOO SLOW!
# traceroute=`which traceroute`
if [ -n "$traceroute" ]; then
	echo $STRING_TRACE
	complete_trace=`$traceroute -q1 www.google.com 2>&1`
fi

####################################################################
# ahora veamos que programas esta corriendo
####################################################################
echo $STRING_UPTIME_AND_PROCESS

uptime=`uptime`
programas=`ps ux`

####################################################################
# ahora veamos que archivos ha tocado el idiota
####################################################################
echo $STRING_MODIFIED_FILES

# no incluimos los archivos carpetas ocultas ni los archivos weones de Mac OS
archivos=`find $ruta_archivos \( ! -regex '.*/\..*/..*' \) -type f -mmin -$minutos 2>&1`
# archivos=`find ~/. \( ! -regex '.*/\..*/\.DS_Store' \) -type f -mmin -$minutos`

####################################################################
# ahora veamos a donde esta conectado
####################################################################
echo $STRING_ACTIVE_CONNECTIONS

connections=`netstat -taue | grep -i established`

####################################################################
# ahora los metemos en el texto que va a ir en el mail
####################################################################
echo $STRING_WRITE_EMAIL
. lang/$lang

####################################################################
# veamos si podemos sacar una foto del tipo con la camara del tarro.
# de todas formas un pantallazo para ver que esta haciendo el idiota
####################################################################
echo $STRING_TAKE_IMAGE

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

echo $STRING_TAKE_IMAGE_DONE

####################################################################
# ahora la estocada final: mandemos el mail
####################################################################
echo $STRING_SENDING_EMAIL
complete_subject="$subject @ `date +"%a, %e %Y %T %z"`"
echo "$texto" > msg.tmp

# si no pudimos sacar el pantallazo o la foto, limpiamos las variables
if [ ! -e "$picture" ]; then
	picture=''
fi

if [ ! -e "$screenshot" ]; then
	screenshot=''
# else
	# Comprimimos el pantallazo? (A veces es medio pesado)
	# echo " -- Comprimiento pantallazo..."
	# tar zcf $screenshot.tar.gz $screenshot
	# screenshot=$screenshot.tar.gz
fi

emailstatus=`./sendEmail -f "$from" -t "$emailtarget" -u "$complete_subject" -s $smtp_server -a $picture $screenshot -o message-file=msg.tmp tls=auto username=$smtp_username password=$smtp_password`

if [[ "$emailstatus" =~ "ERROR" ]]; then
	echo $STRING_ERROR_EMAIl
fi

####################################################################
# ok, todo bien. ahora limpiemos la custion
####################################################################
echo $STRING_REMOVE_EVIDENCE

if [ -e "$picture" ]; then
	rm $picture
fi
if [ -e "$screenshot" ]; then
	rm $screenshot
fi
rm msg.tmp

####################################################################
# change desktop wallpaper with a BIG image to alert nearby people (great idea @warorface!)
####################################################################

if [ $alertwallpaper == 'y' ]; then

	echo " -- Changing the wallpaper to alert him and nearby users..."
	# we need the full path to the files (and we'll asume the script is being run from prey's folder)
	wallpaper=`pwd`/$wallpaper

	if [ $platform == 'Linux' ]; then

		gconftool=`which gconftool-2`
		kdesktop=`which kdesktop`
		xfce=`which xfconf-query`

		if [ -n "$gconftool" ]; then

			$gconftool --type string --set /desktop/gnome/background/picture_filename $wallpaper
			$gconftool --type string --set /desktop/gnome/background/picture_options 'zoom'

		elif [ -n "$kdesktop" ]; then # untested

			$kdesktop KBackgroundIface setWallpaper $wallpaper 5

		elif [ -n "$xfce" ]; then # requires xfce 4.6

			$xfce -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s $wallpaper

		fi

	else # really untested

		# this code belongs to Katy Richard
		# http://thingsthatwork.net/index.php/2008/02/07/fun-with-os-x-defaults-and-launchd/

		defaults write com.apple.Desktop Background "{default = {ChangePath = '~/Pictures'; ChooseFolderPath = '~/Pictures'; CollectionString = Wallpapers; ImageFileAlias = <00000000 00e00003 00000000 c2cc314a 0000482b 00000000 00089e0c 001be568 0000c2fe 8ab30000 00000920 fffe0000 00000000 0000ffff ffff0001 00100008 9e0c0007 4cea0007 4cb40013 52b2000e 00260012 00740068 00650065 006d0070 00690072 0065005f 00310036 00380030 002e006a 00700067 000f001a 000c004d 00610063 0069006e 0074006f 00730068 00200048 00440012 00355573 6572732f 6b726963 68617264 2f506963 74757265 732f5761 6c6c7061 70657273 2f746865 656d7069 72655f31 3638302e 6a706700 00130001 2f000015 0002000f ffff0000 >; ImageFilePath = $wallpaper; Placement = Crop; TimerPopUpTag = 6; };}"

		# we need to restart the dock to make the new wallpaper visible
		killall Dock

	fi

fi

####################################################################
# le avisamos al ladron que esta cagado?
# TODO: esto solo funciona con GNOME y KDE
####################################################################

if [ $alertuser == 'y' ]; then

	echo " -- Showing the guy our alert message..."

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
			$zenity --error --text "$alertmsg"

		elif [ -n "$kdialog" ]; then #untested!

			$kdialog --error "$alertmsg"

		fi

	fi

fi

####################################################################
# reiniciamos X para wevearlo mas aun?
####################################################################
if [ $killx == "y" ]; then # muahahaha

	echo $STRING_XKILL

	# ahora validamos por GDM, KDM, XDM y Entrance, pero hay MUCHO codigo repetido. TODO: reducir!
	if [ $platform == 'Linux' ]; then
		pkill "gdm|kdm|xdm|entrance"
	else
		echo $STRING_MACKILL
	fi

fi

####################################################################
# this is the end, my only friend
####################################################################
echo -e $STRING_DONE
