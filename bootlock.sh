#!/bin/bash

####################################################################
# Bootlock v0.1 - by Tomas Pollak (bootlog.org)
# URL : http://bootlock.bootlog.org
# License: GPLv3
# Requisites: UUencode (sharutils) and Sendmail or Mailx
####################################################################

####################################################################
# configuracion
####################################################################

# lo basico
url=PON AQUI TU URL
alertuser=0
killx=0

# mail
from='no-reply@dominio.com'
emailtarget='tucorreo@dominio.com'
subject="Bootlock status report"

# transcurso de tiempo en que fueron modificados los archivos, en minutos
minutos=100

#archivos
attachment_path=/tmp/bootlock.jpg

# backup ?
# backup_path=~/.bootlock

####################################################################
# primero revisemos el status, si estamos ok o no
####################################################################
if [ -n "$url" ]; then
	echo 'Revisando URL...'
	status=`wget -q -O - $url`
	if [ "${status// /}" = "OK" ]; then
		echo $status
		exit
	else
		echo "$status... HOLY SHIT!"
	fi
fi

####################################################################
# partamos por ver cual es nuestro IP publico
####################################################################
echo "Obteniendo IP publico..."

publico=`wget -q -O - checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`

####################################################################
# ahora el IP interno
####################################################################
echo "Obteniendo IP privado..."

interno=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`

####################################################################
# ahora el gateway, solo por si aca
####################################################################
echo "Obteniendo enrutamiento interno..."

routes=`route -n`

####################################################################
# ahora veamos que archivos ha tocado el idiota
####################################################################
echo "Obteniendo listado de archivos modificados..."

archivos=`find ~/. \( ! -regex '.*/\..*/\.DS_Store' \) -type f -mmin -$minutos` # no incluimos los archivos y carpetas ocultas
# archivos=`find . \( ! -regex '.*/\..*' \) -type f -mmin -$tiempo | awk '{sed -e "s/\n/\\n/g" $1}'`

####################################################################
# ahora veamos que programas esta corriendo
####################################################################
echo "Obteniendo listado de programas en ejecucion..."

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
Bootlock report!

Datos de conexion
--------------------------------------------------------------------
IP Publico: $publico. IP interno: $interno.

Enrutado de red
--------------------------------------------------------------------
$routes

En los ultimos $minutos minutos ha modificado los siguientes archivos
--------------------------------------------------------------------
$archivos

Ahora esta corriendo los siguientes programas
--------------------------------------------------------------------
$programas

Y esta conectado a los siguientes lugares
--------------------------------------------------------------------
$connections


Ahora a agarrar al maldito!

--
Tu humilde servidor, Bootlock! :)
"

####################################################################
# veamos si podemos sacar una foto del tipo con la camara del tarro.
# si no saquemos un pantallazo para ver que esta haciendo el idiota
####################################################################
echo "Obteniendo imagen para delatarlo..."

if [ -f "isightcapture" ]; then
	./isightcapture $attachment_path
else

	# ahora veamos si tenemos import para poder sacar pantallazo
	type 'import' > /dev/null 2>&1
	if [ $? -gt 0 ]; then
		echo "No tenemos como sacar el pantallazo"
		# TODO: intentar con otro?
	else
		import -window root $attachment_path
	fi

fi

echo "Foto sacada!"

####################################################################
# La comprimimos?
####################################################################
# echo "Comprimiento imagen..."
# tar zcf $attachment_path.tar.gz $attachment_path
# attachment_path=$attachment_path.tar.gz

####################################################################
# ahora la estocada final: mandemos el mail
####################################################################
echo "Enviando el correo..."

CONTENT=$texto
msgdate=`date +"%a, %e %Y %T %z"`
boundary=GvXjxJ+pjyke8COw
archdate=`date +%F`
attachment=`basename "$attachment_path"`
archattachment="${archdate}-${attachment}"
mimetype=`file -i $attachment_path | awk '{ print $2 }'`

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
        cat "$attachment_path" >> msg.tmp
else
        uuencode -m $attachment_path $attachment | sed '1d' >> msg.tmp
fi

echo  >> msg.tmp
echo "--$boundary--" >> msg.tmp
email=`cat msg.tmp`

sendmail=`which sendmail`
if [ -n "$sendmail" ]; then
	mailprog=$sendmail
else
	mailx=`which mailx`
	mailprog=$mailx
fi

if [ "$mailprog" != "" ]; then
	echo "$email" | $mailprog -t
fi

####################################################################
# ok, todo bien. ahora limpiemos la custion
####################################################################
echo "Eliminando la evidencia..."

rm msg.tmp
rm $attachment_path

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

echo "...listaylor!"

####################################################################
# reiniciamos X para wevearlo mas aun?
####################################################################
if [ $killx == 1 ]; then

	echo "Botandolo del servidor grafico..."
	killall gdm

fi
