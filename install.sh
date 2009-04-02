#!/bin/bash
####################################################################
# Prey Installation Script - by Tomas Pollak (bootlog.org)
# URL : http://prey.bootlog.org
# License: GPLv3
####################################################################

version='0.1'
config_file=config
prey_file=prey.sh
separator="----------------------------------------"
platform=`uname`
linux_packages='wget traceroute scrot'

if [ $platform == 'Darwin' ]; then
	DEFAULT_INSTALLPATH='/usr/share/prey'
else
	DEFAULT_INSTALLPATH='/usr/share/prey'
fi

	# first we should ask the neccesary questions so as to generate the config automatically

	echo -e "\n####################################"
	echo "### Prey $version installation script ###"
	echo "### By Tomas Pollak, bootlog.org ###"
	echo -e "####################################\n"

	# set installation path
	echo -e $separator
	echo -n " -> Where do you want us to put the script? [$DEFAULT_INSTALLPATH] "
	read INSTALLPATH
	if [ "$INSTALLPATH" == "" ]; then
		INSTALLPATH=$DEFAULT_INSTALLPATH
	else
		echo " -- Ok, setting $INSTALLPATH as our install path."
	fi

	# lets check if the installpath exists and create it if not
	if [ ! -d $INSTALLPATH ]; then
		sudo mkdir -p $INSTALLPATH
	else
		echo " -- Config file exists! Would you like to skip all the boring questions? (Not recommended) [n]"
		read SKIP
		if [ "$SKIP" == "y" ]; then

			echo -e " -- Alright, well just update the necesary files!\n"

		else

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
			echo -n " -> Type in your smtp username: (i.e. mailbox@gmail.com) [$EMAIL] "
			read SMTP_USER
			if [ "$SMTP_USER" == "" ]; then
				echo -e " -- Using the full email as the SMTP username..."
				SMTP_USER=$EMAIL
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
			sed -i -e "s/emailtarget='.*'/emailtarget='$EMAIL'/" $config_file
			sed -i -e "s/url='.*'/url='$URL'/" $config_file
			sed -i -e "s/-SLASH-/\//g" $config_file
			sed -i -e "s/smtp_server='.*'/smtp_server='$SMTP_SERVER'/" $config_file
			sed -i -e "s/smtp_username='.*'/smtp_username='$SMTP_USER'/" $config_file
			sed -i -e "s/smtp_password='.*'/smtp_password='$SMTP_PASS'/" $config_file

		fi

	fi

	if [ $platform == 'Linux' ]; then

		echo -e $separator
		echo -e " -- Ok, installing necesary software...\n"

		distro=`cat /proc/version 2>&1`

		# TODO: add check for other distros
		# TODO: the sudo method probably wont work in suse & arch. we should su and then do all the stuff

		if [[ "$distro" =~ "Ubuntu" ]]; then
			sudo apt-get install $linux_packages streamer libio-socket-ssl-perl libnet-ssleay-perl
		elif [[ "$distro" =~ "Fedora|Redhat|CentOS" ]]; then
			# seems they also need these packages: perl-TermReadKey perl-MIME-Lite perl-File-Type
			# from EPEL repo (http://fedoraproject.org/wiki/EPEL)
			sudo yum install $linux_packages xawtv perl-IO-Socket-SSL perl-Net-SSLeay
		elif [[ "$distro" =~ "SUSE" ]]; then
			# its been a long time since i used suse, is smart the default package manager now?
			# TODO: add perl lib packages
			sudo smart install $linux_packages streamer # faltan los otros, alguien sabe como se llaman?
		elif [[ "$distro" =~ "Archlinux" ]]; then
			# TODO: add perl lib packages
			sudo pacman -S $linux_packages streamer  # faltan los otros, alguien sabe como se llaman?
		fi

	elif [ $platform == 'Darwin' ]; then

		echo -e $separator
		echo -e " -- Copying iSightCapture to $INSTALLPATH..."
		sudo cp isightcapture $INSTALLPATH
		sudo chmod +x $INSTALLPATH/isightcapture

	fi

	echo -e $separator
	echo -e "\n -- Copying necessary files to $INSTALLPATH and setting permissions..."
	# first the basic files
	sudo cp -f $prey_file sendEmail $INSTALLPATH
	sudo chmod +x $INSTALLPATH/sendEmail $INSTALLPATH/$prey_file

	# now the language files
	sudo cp -r lang $INSTALLPATH
	sudo chmod +x $INSTALLPATH/lang/spanish $INSTALLPATH/lang/english

	if [ "$SKIP" != "y" ]; then

		sudo cp $config_file $INSTALLPATH
		sudo chmod 700 $INSTALLPATH/$config_file # no read access to other users, for security

	fi

	echo -e $separator
	echo -e " -- Adding crontab entry..."
	# well also remove any line invoking prey if it was already there, just to make sure
	(sudo crontab -l | grep -v prey; echo "*/$TIMING * * * * cd $INSTALLPATH; ./$prey_file") | sudo crontab -

	echo -e $separator
	echo -e "\n -- Everything OK! Prey is up and running now. You can now delete this directory safely. "
	echo -e " -- If you ever want to uninstall Prey, just delete the $INSTALLPATH directory and remove Prey's line in root's crontab: \n"
	echo -e " \t $ sudo rm -Rf $INSTALLPATH\n \t $ sudo crontab -l | grep -v prey | sudo crontab -\n\n"
