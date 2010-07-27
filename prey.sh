#!/bin/bash
####################################################################
# Prey Client - by Tomas Pollak (bootlog.org)
# URL: http://preyproject.com
# License: GPLv3
####################################################################

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
# 	log ' -- Prey is already running!'
# 	exit 1
# fi

# trap "echo -- Kill signal detected.; wait" SIGTERM SIGKILL SIGQUIT

log "${cyan}$STRING_START ### `uname -a`${color_end}\n"

####################################################################
# lets check if we're actually connected
# if we're not, lets try to connect to a wifi access point
####################################################################

check_net_status
if [ $connected == 0 ]; then

	if [ "$auto_connect" == "y" ]; then
		log "$STRING_TRY_TO_CONNECT"
		try_to_connect
	fi

	# ok, lets check again, after waiting three seconds
	sleep 3
	check_net_status
	if [ $connected == 0 ]; then
		log "$STRING_NO_CONNECT_TO_WIFI"
	fi
fi

####################################################################
# check API key and perform stuff accordingly
####################################################################

if [ $connected == 1 ]; then

	log ' -- Got network connection!'

	# if we dont have an API key and the configurator is there, run it unless the 25 minutes have passed since installing Prey
	if [[ -z "$api_key" && -f "$config_program" && -z `is_process_running prey-config` && -n `was_file_modified "$base_path/prey.sh" 25` ]]; then

		log "\n${bold} >> Running configurator!${bold_end}\n"
		"$config_program" &
		exit 2 #

	# we do have an API key but no device key, so let's try to add this device under the account
	elif [[ -n "$api_key" && -z "$device_key" ]]; then

		log "\n${bold} >> Registering device under account!${bold_end}\n"
		self_setup

	fi

fi

####################################################################
# verify if installation and keys are correct, if requested
####################################################################

if [ -n "$check_mode" ]; then

	log "\n${bold} >> Verifying Prey installation...${bold_end}\n"
	verify_installation

	log "\n${bold} >> Verifying API and Device keys...${bold_end}\n"
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
	log "$STRING_CHECK_URL"

	check_device_status
	parse_headers

	process_config
	process_module_config

	log "\n${bold} >> Verifying status...${bold_end}\n"
	log " -- Got status code $status!"

	if [ "$status" == "$missing_status_code" ]; then

		log "$STRING_PROBLEM"

		####################################################################
		# initialize and fire off active modules
		####################################################################

		set +e # error mode off, just continue if a module fails
		log " -- Running active report modules..."
		run_active_modules

		####################################################################
		# lets send whatever we've gathered
		####################################################################

		log "\n${bold} >> Sending report!${bold_end}\n"
		send_report

		log "\n$STRING_DONE"

	else
		log "$STRING_NO_PROBLEM"
	fi
fi

####################################################################
# if we have any pending actions, run them
####################################################################

# before we need to make sure the actions are actually set up
if [ -z "$status" ]; then
	process_module_config
fi

check_running_actions
run_pending_actions &
delete_tmpdir

exit 0
