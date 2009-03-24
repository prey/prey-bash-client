#!/bin/bash

####################################################################
# Prey v0.1 Installation Script - by Tomas Pollak (bootlog.org)
# URL : http://github.com/tomas/prey
# License: GPLv3
# Requisites for Linux: Wget, Traceroute, Streamer (for webcam capture) and Perl Libs IO::Socket and NET::SSLeay (yeah, i know)
####################################################################

filename=prey.sh
separator="----------------------------------------"
platform=`uname`
linux_packages='wget streamer traceroute libio-socket-ssl-perl libnet-ssleay-perl'

	# first we should ask the neccesary questions so as to generate the config automatically

	echo -e "\n####################################"
	echo "### Prey 0.1 installation script ###"
	echo "### By Tomas Pollak, bootlog.org ###"
	echo -e "####################################\n"

	# set installation path
	echo -e $separator
	echo -n " -> Where do you want us to put the script? [/usr/local/bin] "
	read INSTALLPATH
	if [ "$INSTALLPATH" == "" ]; then
		INSTALLPATH='/usr/local/bin'
	elif [ -d $INSTALLPATH ]; then
		echo " -- Ok, setting $INSTALLPATH as our install path."
	else
		echo " !! Directory does not exist! Please make sure the path exist and try again."
		exit
	fi

	# get the email
	echo -e $separator
	echo -n " -> What email address would you like the email sent to? (i.e. mailbox@domain.com) [] "
	read EMAIL
	if [ "$EMAIL" == "" ]; then
		echo -e " !! You need to define an inbox. Exiting...\n"
		exit
	fi

	# setup SMTP
	echo -e $separator
	echo -n " -> Which smtp server should we use? (with port) [smtp.gmail.com:587] "
	read SMTP_SERVER
	if [ "$SMTP_SERVER" == "" ]; then
		SMTP_SERVER='smtp.gmail.com:587'
	fi

	# SMTP user
	echo -e $separator
	echo -n " -> Type in your smtp username: (i.e. mailbox@gmail.com) [] "
	read SMTP_USER
	if [ "$SMTP_USER" == "" ]; then
		echo -e " !! You need to type in a valid username. Exiting...\n"
		exit
	fi

	# SMTP pass
	echo -e $separator
	echo -n " -> Type in your smtp password: [] "
	read -s SMTP_PASS
	echo -e "\n"
	if [ "$SMTP_PASS" == "" ]; then
		echo -e " !! You need to type in a valid password. Exiting...\n"
		exit
	fi

	# setup URL check
	echo -e $separator
	echo -n " -- Would you like Prey to check a URL? (No means the report is generated each time the program runs) [n] "
	read CHECK
	case "$CHECK" in
	[yY] )
		# which url then
		echo -e $separator
		echo -n " -- Ok, which URL would it be then? [i.e. http://myserver.com/prey_check_url] "
		read URL
		if [ "$URL" == "" ]; then
			echo -e " !! You need to define a URL. Exiting...\n"
			exit
		fi
		# URL=`echo $URL | sed -f urlencode.sed`
		# urlencoding no nos sirve, porque despues wget no puede resolver la direccion. dirty hack entonces.
		URL=`echo $URL | sed "s/\//-SLASH-/g"`
		;;
	[nN] ) # echo "OK, no URL check then."
		URL=""
	;;
	* ) # echo "OK, no URL check then."
		URL=""
	;;
	esac

	# run interval
	echo -e $separator
	echo -n " -- Ok, last one. How frequent (in minutes) would you like Prey to be ran? [10] "
	read TIMING
	if [ "$TIMING" == "" ]; then
		TIMING=10
	fi

	echo -e $separator
	echo -e " -- Ok, setting up configuration values..."
	sed -i -e "s/emailtarget='.*'/emailtarget='$EMAIL'/" $filename
	sed -i -e "s/url='.*'/url='$URL'/" $filename
	sed -i -e "s/-SLASH-/\//g" $filename
	sed -i -e "s/smtp_server='.*'/smtp_server='$SMTP_SERVER'/" $filename
	sed -i -e "s/smtp_username='.*'/smtp_username='$SMTP_USER'/" $filename
	sed -i -e "s/smtp_password='.*'/smtp_password='$SMTP_PASS'/" $filename

	if [ $platform == 'Linux' ]; then

		echo -e $separator
		echo -e " -- Ok, installing necesary software...\n"

		distro=`cat /proc/version 2>&1`

		# TODO: add check for other distros
		# TODO: the sudo method probably wont work in suse & arch. we should su and then do all the stuff

		if [[ "$distro" =~ "Ubuntu" ]]; then
			sudo apt-get install $linux_packages
		elif [[ "$distro" =~ "Fedora|Redhat" ]]; then
			sudo yum install $linux_packages
		elif [[ "$distro" =~ "SUSE" ]]; then
			# its been a long time since i used suse, is smart the default package manager now?
			sudo smart install $linux_packages
		elif [[ "$distro" =~ "Archlinux" ]]; then
			sudo pacman -S $linux_packages
		fi

	elif [ $platform == 'Darwin' ]; then

		echo -e $separator
		echo -e " -- Copying ISightCapture to $INSTALLPATH..."
		sudo cp isightcapture $INSTALLPATH

	fi

	echo -e $separator
	echo -e "\n -- Copying Prey and Email Sender to $INSTALLPATH..."
	sudo cp $filename $INSTALLPATH
	sudo cp sendEmail $INSTALLPATH

	echo -e $separator
	echo -e " -- Setting permissions..."
	sudo chmod 750 $INSTALLPATH/$filename # no read access to other users, for security
	sudo chmod 750 $INSTALLPATH/sendEmail

	echo -e $separator
	echo -e " -- Adding crontab entry..."
	(sudo crontab -l; echo "*/$TIMING * * * * $INSTALLPATH/$filename") | sudo crontab -

	echo -e $separator
	echo -e "\n -- Everything OK! Prey is up and running now. You can now delete this directory safely. "
	echo -e " -- If you ever want to uninstall Prey, remove the file in $INSTALLPATH and the last line in root's crontab. \n\n"
