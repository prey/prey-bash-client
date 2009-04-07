#!/bin/bash
####################################################################
# Prey Installation Script - by Tomas Pollak (bootlog.org)
# URL : http://prey.bootlog.org
# License: GPLv3
####################################################################

version='0.2'
config_file=config
temp_config_file=temp_config
prey_file=prey.sh
platform=`uname`
linux_packages='wget traceroute scrot'

TIMING=10
DEFAULT_INSTALLPATH='/usr/share/prey'

separator="--------------------------------------------------------------------------------"

	echo -e "\n####################################"
	echo "### Prey $version installation script ###"
	echo "### By Tomas Pollak, bootlog.org ###"
	echo -e "####################################\n"

	# define language
	echo -e $separator
	echo -n " -> Set default language for Prey (en/es) [en] "
	read LANGUAGE
	if [ "$LANGUAGE" == "" ]; then
		echo " -- Defaulting to Prey in english..."
		LANGUAGE='en'
		. lang/$LANGUAGE
	elif [ -e "lang/$LANGUAGE" ]; then
		. lang/$LANGUAGE
		echo "$HELLO_IN_LANGUAGE"
	else
		echo -e " !! Unsupported language! Remember to write its valid code (en for english, es for espanol, etc)\n"
		exit
	fi

	# we need to check for previous versions of prey (which were installed in /usr/local/bin or /usr/bin)
	# well delete them since thats not the place where they should be
	if [ -e "/usr/local/bin/prey.sh" ]; then

		previous_path="/usr/local/bin"

	elif [ -e "/usr/bin/prey" ]; then

		previous_path="/usr/bin"

	fi

	if [ -n "$previous_path" ]; then

		echo -e "It seems you had already installed Prey 0.1 in $previous_path.\nThe new version uses a different path for the installation,"
		echo -e "so we should remove the old ones since they won't be used anymore."
		echo -n "Should we do this automatically for you? [y] "
		read DELETE
		if [[ "$DELETE" == "" || $DELETE == "y" ]]; then

			echo -e "$DELETING_OLD_FILES"

			sudo rm $previous_path/prey.sh
			sudo rm $previous_path/sendEmail

			if [ "$platform" == "Darwin" ]; then

				sudo rm $previous_path/isightcapture

			fi

		fi

	fi

	# ok, now lets ask the neccesary questions so as to generate the config automatically

	# set installation path
	echo -e $separator
	echo -n "$WHERE_TO_INSTALL_PREY"
	read INSTALLPATH
	PARENT_PATH=`echo $INSTALLPATH | sed "s/\/prey//"`
	if [ "$INSTALLPATH" == "" ]; then
		INSTALLPATH=$DEFAULT_INSTALLPATH
	elif [ ! -d "$PARENT_PATH" ]; then
		echo -e "$INVALID_INSTALL_PATH"
		exit
	else
		echo "$SETTING_INSTALL_PATH"
	fi

	# lets check if the installpath exists and create it if not
	if [ ! -d $INSTALLPATH ]; then
		sudo mkdir -p $INSTALLPATH
		SKIP=n
	elif [ -e $INSTALLPATH/$config_file ]; then
		echo -e $separator
		echo -n "$CONFIG_FILE_EXISTS"
		read SKIP
	fi

	if [ "$SKIP" == "y" ]; then

		echo -e "$SKIP_INSTALL_QUESTIONS"

	else

		# get the email
		echo -e $separator
		echo -n "$ENTER_EMAIL_ADDRESS"
		read EMAIL
		if [ "$EMAIL" == "" ]; then
			echo -e "$INVALID_EMAIL_ADDRESS"
			exit
		fi

		# setup SMTP
		echo -e $separator
		echo -n "$ENTER_SMTP_SERVER"
		read SMTP_SERVER
		if [ "$SMTP_SERVER" == "" ]; then
			SMTP_SERVER='smtp.gmail.com:587'
		fi

		# SMTP user
		echo -e $separator
		echo -n "$ENTER_SMTP_USER"
		read SMTP_USER
		if [ "$SMTP_USER" == "" ]; then
			echo -e "$DEFAULT_SMTP_USER"
			SMTP_USER=$EMAIL
		fi

		# SMTP pass
		echo -e $separator
		echo -n "$ENTER_SMTP_PASS"
		read -s SMTP_PASS
		echo -e "\n"
		if [ "$SMTP_PASS" == "" ]; then
			echo -e "$INVALID_SMTP_PASS"
			exit
		fi

		# setup URL check
		echo -e $separator
		echo -n "$CHECK_URL_OR_NOT"
		read CHECK
		case "$CHECK" in
		[yY] )
			# which url then
			echo -e $separator
			echo -n "$ENTER_URL"
			read URL
			if [ "$URL" == "" ]; then
				echo -e "$INVALID_URL"
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
		echo -n "$SET_TIMING"
		read TIMING
		if [ "$TIMING" == "" ]; then
			TIMING=10
		fi

		echo -e $separator
		echo -e " -- Ok, setting up configuration values..."
		cp $config_file $temp_config_file
		sed -i -e "s/lang='.*'/lang='$LANGUAGE'/" $temp_config_file
		sed -i -e "s/emailtarget='.*'/emailtarget='$EMAIL'/" $temp_config_file
		sed -i -e "s/url='.*'/url='$URL'/" $temp_config_file
		sed -i -e "s/-SLASH-/\//g" $temp_config_file
		sed -i -e "s/smtp_server='.*'/smtp_server='$SMTP_SERVER'/" $temp_config_file
		sed -i -e "s/smtp_username='.*'/smtp_username='$SMTP_USER'/" $temp_config_file
		sed -i -e "s/smtp_password='.*'/smtp_password='$SMTP_PASS'/" $temp_config_file

	fi

	if [ $platform == 'Linux' ]; then

		echo -e $separator
		echo -e "$INSTALLING_SOFTWARE"

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
		echo -e "$COPYING_ISIGHTCAPTURE"
		sudo cp isightcapture $INSTALLPATH
		sudo chmod +x $INSTALLPATH/isightcapture

	fi

	echo -e $separator
	echo -e "$COPYING_FILES"
	# first the basic files
	sudo cp -f $prey_file sendEmail $INSTALLPATH
	sudo chmod +x $INSTALLPATH/sendEmail $INSTALLPATH/$prey_file

	# now the language files
	sudo cp -r lang alerts $INSTALLPATH
	sudo chmod +x $INSTALLPATH/lang/spanish $INSTALLPATH/lang/english

	if [ "$SKIP" != "y" ]; then

		sudo cp $temp_config_file $INSTALLPATH/$config_file
		sudo chmod 700 $INSTALLPATH/$config_file # no read access to other users, for security
		rm $temp_config_file

	fi

	echo -e $separator
	echo -e "$ADDING_CRONTAB"
	# well also remove any line invoking prey if it was already there, just to make sure
	(sudo crontab -l | grep -v prey; echo "*/$TIMING * * * * cd $INSTALLPATH; ./$prey_file") | sudo crontab -

	echo -e $separator
	echo -e "\n -- Everything OK! Prey is up and running now. You can now delete this directory safely. "
	echo -e " -- If you ever want to uninstall Prey, just delete the $INSTALLPATH directory"
	echo -e "and remove Prey's line in root's crontab: \n"
	echo -e " \t $ sudo rm -Rf $INSTALLPATH\n \t $ sudo crontab -l | grep -v prey | sudo crontab -\n"
	echo -e " -- For updates remember to check http://prey.bootlog.org!\n\n"
