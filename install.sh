#!/bin/bash
####################################################################
# Prey Installation Script - by Tomas Pollak (bootlog.org)
# URL : http://preyproject.com
# License: GPLv3
####################################################################

version='0.3'
config_file=config
temp_config_file=temp_config
prey_file=prey.sh
platform=`uname`
linux_packages='wget traceroute scrot'

TIMING=10
DEFAULT_INSTALLPATH='/usr/share/prey'
WEB_SERVICE_URL='http://control.preyproject.com'

separator="--------------------------------------------------------------------------------"

	echo -e "\n\t\033[1m########################################"
	echo -e "\t###   Prey $version installation script   ###"
	echo -e "\t###   By Tomas Pollak, bootlog.org   ###"
	echo -e "\t########################################\033[0m\n"

	# define language
	echo -e $separator
	echo -n " -> Set default language for Prey (en/es/sv) [en] "
	read LANGUAGE
	if [ "$LANGUAGE" == "" ]; then
		echo " -- Defaulting to Prey in english..."
		LANGUAGE='en'
		. lang/$LANGUAGE
	elif [ -e "lang/$LANGUAGE" ]; then
		. lang/$LANGUAGE
		echo "$HELLO_IN_LANGUAGE"
	else
		echo -e " !! Unsupported language! Remember to write its valid code (en for english, es for espanol, sv for svenka, etc)\n"
		exit
	fi

	# we need to check for previous versions of prey (which were installed in /usr/local/bin or /usr/bin)
	# well delete them since thats not the place where they should be
	if [ -e "/usr/local/bin/prey.sh" ]; then

		previous_path="/usr/local/bin"

	elif [ -e "/usr/bin/prey.sh" ]; then

		previous_path="/usr/bin"

	fi

	if [ -n "$previous_path" ]; then

		echo -e "$IT_SEEMS_PATH $previous_path.$DIFFERENT_PATH"
		echo -e "$REMOVE_OLD_FILES"
		echo -n "$ASK_RM_OLD_FILES ($YES_NO) [$YES] "
		read DELETE
		if [[ "$DELETE" == "" || $DELETE == "$YES" ]]; then

			echo -e "$DELETING_OLD_FILES"

			sudo rm $previous_path/prey.sh
			sudo rm $previous_path/sendEmail

			if [ "$platform" == "Darwin" ]; then

				sudo rm $previous_path/isightcapture

			fi

		fi

	fi

	# ok, now lets ask the neccesary questions so as to generate the config automatically

  # uncomment below if you want the installer to ask you where to install prey
  # now we always install to /usr/share/prey, as it seems it works for everyone

	# set installation path
	# echo -e $separator
	# echo -n "$WHERE_TO_INSTALL_PREY"
	# read INSTALLPATH
	# PARENT_PATH=`echo $INSTALLPATH | sed "s/\/prey//"`
	# if [ "$INSTALLPATH" == "" ]; then
	 	INSTALLPATH=$DEFAULT_INSTALLPATH
	# 	echo -e "$USING_DEFAULT_INSTALL_PATH"
	# elif [ ! -d "$PARENT_PATH" ]; then
	# 	echo -e "$INVALID_INSTALL_PATH"
	# 	exit
	# else
	# 	echo "$SETTING_INSTALL_PATH"
	# fi

	# now that we have the install path we need to fetch to rerun this
	# so as to insert the INSTALL_PATH variable into the other messages
	# TODO: make this in a cleaner way
	. lang/$LANGUAGE

	# lets check if the installpath exists and create it if not
	if [ ! -d $INSTALLPATH ]; then
		# sudo mkdir -p $INSTALLPATH
		SKIP=n
	elif [ -e $INSTALLPATH/$config_file ]; then
		echo -e $separator
		echo -n "$CONFIG_FILE_EXISTS"
		read SKIP
	fi

	if [ "$SKIP" == "$YES" ]; then

		echo -e "$SKIP_INSTALL_QUESTIONS"

	else

		# what reporting method?
		echo -e $separator
		echo -n "$DEFINE_REPORT_METHOD"
		read REPORT_METHOD
		if [ "$REPORT_METHOD" == "" ]; then
			REPORT_METHOD='email'
			echo -e "$DEFAULT_REPORT_METHOD"
		elif [ "$REPORT_METHOD" == 'web' ]; then

			echo -e $separator
			echo -n "$IS_REGISTERED_ON_WEB ($YES_NO) [n] "
			read USER_REGISTERED
			if [ "$USER_REGISTERED" == "$YES" ]; then

				echo -n "$ADD_API_KEY"
				read API_KEY
				# the device keys are six digit long hex strings
				if [[ ${#API_KEY} != 12 ]]; then
					echo -e "$INVALID_API_KEY"
					exit
				fi

			else
				#TODO: Translate and put in lang files.
				echo -n "$DESIRED_USER_WEB"
				read WEB_USERNAME
				echo -n "$ASK_EMAIL_WEB"
				read WEB_EMAIL
				echo -n "$DESIRED_PASS_WEB"
				read -s WEB_PASSWORD

				if [[ -n "$WEB_USERNAME" && -n "$WEB_EMAIL" && -n "$WEB_PASSWORD" ]]; then

					user_response=`curl -s -d "user[login]=$WEB_USERNAME&user[email]=$WEB_EMAIL&user[password]=$WEB_PASSWORD&user[password_confirmation]=$WEB_PASSWORD" $WEB_SERVICE_URL/users.xml`
					if [[ "$user_response" =~ 'error' ]]; then
						echo -e -n "\n\n !! $PROBLEM_SIGNUP_WEB $WEB_SERVICE_URL.\n\n"
						echo -e " !! $PROBLEM_RESPONSE_WEB \n\n$user_response.\n\n"
						exit
					fi

					API_KEY=`echo $user_response | sed -n -e 's/.*<api-key>\(.*\)<\/api-key>.*/\1/p'`
					echo -e "\n\n -- Registration succesful! Remember to log in as $WEB_USERNAME in $WEB_SERVICE_URL whenever you want to change your settings or view your reports."
					echo -e " -- By the way, your API Key is $API_KEY. We'll add it to your config file."

				else

					echo -e " !!  Some of the fields for the web service registration are missing! Please try again.\n"
					exit

				fi

			fi

			echo -e $separator
			echo -n " -- Do you want us to add this device automatically to your profile in the web service? ($YES_NO) [$YES] "
			read ADD_DEVICE_AUTO

			if [ "$ADD_DEVICE_AUTO" == 'n' ]; then

				echo -n "$ADD_DEVICE_KEY"
				read DEVICE_KEY
				# the device keys are six digit long hex strings
				if [[ ${#DEVICE_KEY} != 6 ]]; then
					echo -e "$INVALID_DEVICE_KEY"
					exit
				fi
			else
				hostname=`hostname`
				device_response=`curl -s -d "api_key=$API_KEY&device[title]=$hostname&device[device_type]=Desktop" $WEB_SERVICE_URL/devices.xml`

				if [[ "$device_response" =~ 'error' ]]; then
					echo -e -n "!! There was a problem registering your device in the web service. Please try again or just do so directly in $WEB_SERVICE_URL.\n\n"
					echo -e " !! The response we got was this: \n\n$device_response.\n\n"
					exit
				fi

				DEVICE_KEY=`echo $device_response | sed -n -e 's/.*<key>\(.*\)<\/key>.*/\1/p'`
				echo -e "-- Everything ok! Your Device key is $DEVICE_KEY. We'll add it to your config file automagically."

			fi

		fi

		if [ "$REPORT_METHOD" != 'web' ]; then

			# get the email
			echo -e $separator
			echo -n "$ENTER_EMAIL_ADDRESS"
			read EMAIL
			if [ "$EMAIL" == "" ]; then
				echo -e "$INVALID_EMAIL_ADDRESS"
				exit
			fi

			if [ "$REPORT_METHOD" == 'email' ]; then

				# setup SMTP
				echo -e $separator
				echo -n "$ENTER_SMTP_SERVER"
				read SMTP_SERVER
				if [ "$SMTP_SERVER" == "" ]; then
					SMTP_SERVER='smtp.gmail.com:587'
					echo -e "$DEFAULT_SMTP_SERVER"
				fi

				# SMTP user
				echo -e $separator
				echo -n "$ENTER_SMTP_USER [$EMAIL] "
		 		read SMTP_USER
				if [ "$SMTP_USER" == "" ]; then
					echo -e "$DEFAULT_SMTP_USER" $EMAIL.
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

			fi

		fi

		# setup URL check
		echo -e $separator
		echo -n "$CHECK_URL_OR_NOT"
		read CHECK
		case "$CHECK" in
		[yY] )

			if [ "$REPORT_METHOD" == 'web' ]; then
				URL="$WEB_SERVICE_URL/devices/$DEVICE_KEY.xml"
				echo -e "$USING_DEFAULT_APP_URL"
			else
				# which url then
				echo -e $separator
				echo -n "$ENTER_URL"
				read URL
				if [ "$URL" == "" ]; then
					echo -e "$INVALID_URL"
					exit
				fi
			fi
			# dirty hack so that wget can actually resolve the slashes.
			# urlencoding is unneccesary if you can pull a dirty hack, right?
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

		WEB_SERVICE_URL=`echo $WEB_SERVICE_URL | sed "s/\//-SLASH-/g"`

		echo -e $separator
		echo -e " -- Ok, setting up configuration values..."
		cp $config_file $temp_config_file
		sed -i -e "s/lang='.*'/lang='$LANGUAGE'/" $temp_config_file
		sed -i -e "s/web_service='.*'/web_service='$WEB_SERVICE_URL'/" $temp_config_file
		sed -i -e "s/report_method='.*'/report_method='$REPORT_METHOD'/" $temp_config_file
		sed -i -e "s/api_key='.*'/api_key='$API_KEY'/" $temp_config_file
		sed -i -e "s/device_key='.*'/device_key='$DEVICE_KEY'/" $temp_config_file
		sed -i -e "s/emailtarget='.*'/emailtarget='$EMAIL'/" $temp_config_file
		sed -i -e "s/url='.*'/url='$URL'/" $temp_config_file
		sed -i -e "s/smtp_server='.*'/smtp_server='$SMTP_SERVER'/" $temp_config_file
		sed -i -e "s/smtp_username='.*'/smtp_username='$SMTP_USER'/" $temp_config_file
		sed -i -e "s/smtp_password='.*'/smtp_password='$SMTP_PASS'/" $temp_config_file

		sed -i -e "s/-SLASH-/\//g" $temp_config_file # resolve the slash hack

	fi

	# lets create the install path
	sudo mkdir -p $INSTALLPATH

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
			zypper ar http://download.opensuse.org/repositories/X11:/Utilities/openSUSE_11.1/ 'X11:Utilities'
			sudo zypper install $linux_packages streamer # faltan los otros, alguien sabe como se llaman?
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

	# now the language and specific platform files
	sudo cp -R lang alerts platform $INSTALLPATH
	sudo chmod +x $INSTALLPATH/lang/* $INSTALLPATH/platform/*

	if [ "$SKIP" != "$YES" ]; then

		sudo cp $temp_config_file $INSTALLPATH/$config_file
		sudo chmod 700 $INSTALLPATH/$config_file # no read access to other users, for security
		rm $temp_config_file

	fi

	echo -e $separator
	echo -e "$ADDING_CRONTAB"
	# well also remove any line invoking prey if it was already there, just to make sure
	(sudo crontab -l | grep -v prey; echo "*/$TIMING * * * * cd $INSTALLPATH; ./$prey_file") | sudo crontab -

	echo -e $separator
	echo -e "$INSTALL_OK"
