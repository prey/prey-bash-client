#!/bin/bash
####################################################################
# Prey Bash Client - (c) Fork Ltd.
# http://preyproject.com
# License: GPLv3
####################################################################


####################################################################
# Prey should always be run as root. If not, it messes up logging to
# /var/log/prey.log and crontabs
####################################################################

if [ "$(id -u)" != "0" ]; then
   echo "ERROR: Prey.sh must be run as root (sudo ./prey.sh)" 1>&2
   exit 1
fi

PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
readonly base_path=$(dirname "$0")

####################################################################
# base files inclusion
####################################################################

. "$base_path/version"
. "$base_path/config"
[ ! -f "lang/$lang" ] && lang='en' # fallback to english in case the lang is missing
. "$base_path/lang/$lang"
. "$base_path/core/base"
. "$base_path/platform/$os/functions"

# if [ `number_of_instances_of prey.sh` -gt 1 ]; then
# 	log ' -- Prey is already running!'
# 	exit 1
# fi

log "\n${cyan} ## $STRING_START\n ## $(uname -a)\n ## $(date)${color_end}\n"

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

	# ok, lets check again, after waiting a bit
	sleep 5
	check_net_status

	if [ $connected == 0 ]; then

		log "$STRING_NO_CONNECT_TO_WIFI"
		if [ -f "$last_response" ]; then # offline actions were enabled

			log ' -- Offline actions enabled!'
			offline_mode=1
			get_last_response
			process_module_config

		else
			exit 1
		fi

	fi
fi

####################################################################
# check API key and perform stuff accordingly
####################################################################

if [ $connected == 1 ]; then

	log ' -- Got network connection!'

	# we do have an API key but no device key, so let's try to add this device under the account
	if [[ -n "$api_key" && -z "$device_key" ]]; then

		log "\n${bold} >> Registering device under account!${bold_end}\n"
		self_setup

	fi

fi

####################################################################
# verify if installation and keys are correct, if requested
####################################################################

if [ -n "$check_mode" ]; then

	log "\n${bold} == Verifying Prey installation...${bold_end}\n"
	verify_installation

	if [ "$post_method" == "http" ]; then
		log "\n${bold} == Verifying API and Device keys...${bold_end}\n"
		verify_keys
	elif [ "$post_method" == "email" ]; then
		log "\n${bold} == Verifying SMTP settings...${bold_end}\n"
		verify_smtp_settings
	fi

	exit $?

fi

####################################################################
# wait a few seconds to make sure our request doesn't get dropped
# due to clashes with the other zillion requests to the CP
####################################################################

# only do this if Prey is being run from cron in Mac and Linux
if [[ "$os" != "windows" && -n "$(running_from_cron)" && "$post_method" == "http" ]]; then
	seconds_to_wait=$(get_random_number 59)
	log " -- Pausing for ${seconds_to_wait} seconds..."
	sleep $seconds_to_wait
fi

####################################################################
# if there's a URL in the config, lets see if it actually exists
# if it doesn't, the program will shut down gracefully
####################################################################

# create tmpdir for downloading stuff, storing files, etc
create_tmpdir

if [[ $connected == 1 && -n "$check_url" ]]; then

	log "$STRING_CHECK_URL"

	log "\n${bold} == Verifying status...${bold_end}\n"
	check_device_status

	if [ -z "$response_status" ]; then

		log_response_error "$check_url"

	else

		log " -- Got status code $response_status!"
		[ "$response_status" == "$missing_status_code" ] && device_missing=1
		process_config
		process_module_config

		if [ -n "$device_missing" ]; then

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

			log "\n${bold} == Sending report!${bold_end}\n"
			send_report

			log "\n$STRING_DONE"

		else

			log "$STRING_NO_PROBLEM"

		fi

	fi

fi

####################################################################
# if we have any pending actions, run them
####################################################################

check_running_actions

if [ "${#actions[*]}" -gt 0 ]; then
	run_pending_actions & disown -h
else
	cleanup
fi

# if on demand mode was activated, and we're not being by on demand mode itself
if [[ -z "$on_demand_call" && "$on_demand_mode" == "true" ]]; then
	enable_on_demand_mode
fi

# exit 0
