#!/bin/bash

####################################################################
# Bootlock v0.1 - by Tomas Pollak (bootlog.org)
# URL : http://bootlock.bootlog.org
# License: GPLv3
# Requisites for Linux: UUencode (sharutils), Sendmail or Mailx and Streamer (for webcam capture)
####################################################################

separator="----------------------------------------"
platform=`uname`

if [ $platform == 'Linux' ]; then

	# first we should ask the neccesary questions so as to generate the config automatically

	echo -e "\n########################################"
	echo "### Bootlock 0.1 installation script ###"
	echo "### By Tomas Pollak, www.bootlog.org ###"
	echo -e "########################################\n"

	# set installation path
	echo $separator
	echo -n "0) Where do you want us to put the script? [/usr/local/bin] "
	read INSTALLPATH
	if [ "$INSTALLPATH" == "" ]; then
		INSTALLPATH='/usr/local/bin'
	elif [ -d $INSTALLPATH ]; then
		echo " -- Ok, setting $INSTALLPATH as our install path."
	else
		echo " -- Directory does not exist! Exiting..."
		exit
	fi

	# get the email
	echo $separator
	echo -n "1) What email address would you like the email sent to? [i.e. mailbox@domain.com] "
	read EMAIL
	if [ "$EMAIL" == "" ]; then
		echo " -- You need to define an inbox. Exiting..."
		exit
	fi

	# setup URL
	echo $separator
	echo -n "2) Would you like Bootlock to check a URL? (No means the report is generated each time the program runs) [n] "
	read CHECK
	case "$CHECK" in
	[yY] )
		echo $separator
		echo -n "3) Ok, which URL would it be then? [i.e. http://myserver.com/bootlock_check_url] "
		read URL
		if [ "$URL" == "" ]; then
			echo " -- You need to define a URL. Exiting..."
			exit
		fi
		# URL=`echo $URL | sed -f urlencode.sed`
		# urlencoding no nos sirve, porque despues wget no puede resolver la direccion. dirty hack entonces.
		URL=`echo $URL | sed "s/\//-SLASH-/g"`
		# get the email
		echo $separator
		echo -n "4) How frequent (in minutes) would you like Bootlock to run? [10] "
		read TIMING
		if [ "$TIMING" == "" ]; then
			TIMING=10
		fi
		;;
	[nN] ) # echo "OK, no URL check then."
		URL=""
	;;
	* ) # echo "OK, no URL check then."
		URL=""
	;;
	esac

	echo $separator
	echo -e " -- Ok, setting up configuration values..."
	sed -i -e "s/emailtarget='.*'/emailtarget='$EMAIL'/" bootlock.sh
	sed -i -e "s/url='.*'/url='$URL'/" bootlock.sh
	sed -i -e "s/-SLASH-/\//g" bootlock.sh


	echo $separator
	echo -e " -- Ok, installing necesary software..."
	sudo apt-get install sharutils mailx streamer

	echo $separator
	echo -e " -- Copying Bootlock to /usr/local/bin..."
	sudo cp bootlock.sh /usr/local/bin

	echo $separator
	echo -e " -- Setting permissions..."
	sudo chmod 750 /usr/local/bin/bootlock.sh # no read access to other users, for security

	echo $separator
	echo -e " -- Adding crontab "
	(sudo crontab -l; echo "*/$TIMING * * * * /usr/local/bin/bootlock") | sudo crontab -

fi
