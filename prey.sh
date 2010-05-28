#!/bin/bash
####################################################################
# Prey Client - by Tomas Pollak (bootlog.org)
# URL: http://preyproject.com
# License: GPLv3
####################################################################

# set -u
# set -e

PATH=/bin:$PATH # for windows
readonly base_path=`dirname "$0"`

####################################################################
# base files inclusion
####################################################################

. "$base_path/version"
. "$base_path/config"
if [ ! -f "lang/$lang" ]; then # fallback to english in case the lang is missing
	lang='en'
fi
. "$base_path/lang/$lang"
. "$base_path/core/base"
. "$base_path/platform/$os/functions"

# if [ `number_of_instances_of prey.sh` -gt 1 ]; then
# 	echo ' -- Prey is already running!'
# 	exit 1
# fi

echo -e "${cyan}$STRING_START ### `uname -a`${color_end}\n"

####################################################################
# lets check if we're actually connected
# if we're not, lets try to connect to a wifi access point
####################################################################

check_net_status
if [ $connected == 0 ]; then

	if [ "$auto_connect" == "y" ]; then
		echo "$STRING_TRY_TO_CONNECT"
		try_to_connect
	fi

	# ok, lets check again, after waiting three seconds
	sleep 3
	check_net_status
	if [ $connected == 0 ]; then
		echo "$STRING_NO_CONNECT_TO_WIFI"

		if [ -f "$last_response" ]; then # offline actions were enabled
			echo ' -- Offline actions enabled!'
			get_last_response
		else
			exit 1
		fi

	fi
else
	echo ' -- Got network connection!'
fi


####################################################################
# if we have an API key and no Device key, let's try to auto setup
####################################################################

if [[ $connected == 1 && -n "$api_key" && -z "$device_key" ]]; then

	echo -e "\n${bold} >> Running self setup!${bold_end}\n"
	self_setup

fi

####################################################################
# verify if installation and keys are correct, if requested
####################################################################

if [ -n "$check_mode" ]; then

	echo -e "\n${bold} >> Verifying Prey installation...${bold_end}\n"
	verify_installation

	echo -e "\n${bold} >> Verifying API and Device keys...${bold_end}\n"
	verify_keys
	exit $?

fi

####################################################################
# if there's a URL in the config, lets see if it actually exists
# if it doesn't, the program will shut down gracefully
####################################################################

# create tmpdir for downloading stuff, storing files, etc
create_tmpdir

if [[ $connected == 1 && -n "$check_url" ]]; then
	echo "$STRING_CHECK_URL"

	check_device_status
	parse_headers
	# process_response
	process_config

	echo -e "\n${bold} >> Verifying status...${bold_end}\n"
	echo -e " -- Got status code $status!"

	if [ "$status" == "$missing_status_code" ]; then

		echo -e "$STRING_PROBLEM"

		####################################################################
		# initialize and fire off active modules
		####################################################################

		process_module_config

		set +e # error mode off, just continue if a module fails
		echo -e " -- Running active report modules..."
		run_active_modules

		####################################################################
		# lets send whatever we've gathered
		####################################################################

		echo -e "\n${bold} >> Sending report!${bold_end}\n"
		send_report

		echo -e "\n$STRING_DONE"

	else
		echo -e "$STRING_NO_PROBLEM"
	fi
fi

####################################################################
# if we have any pending actions, run them
####################################################################

# before we need to make sure the actions are actually set up
if [ -z "$module_configuration" ]; then
	process_module_config
fi

run_pending_actions
delete_tmpdir

exit 0
