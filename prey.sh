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

	# ok, lets check again, after waiting five seconds
	sleep 5
	check_net_status
	if [ $connected == 0 ]; then
		echo "$STRING_NO_CONNECT_TO_WIFI"
		exit
	fi
else
	echo ' -- Got network connection!'
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

if [ -n "$check_url" ]; then
	echo "$STRING_CHECK_URL"

	check_device_status
	parse_headers
	process_response

	echo -e "\n${bold} >> Verifying status...${bold_end}\n"
	echo -e " -- Got status code $status!"

	if [ "$status" == "$missing_status_code" ]; then

		echo -e "$STRING_PROBLEM"

		####################################################################
		# fire off active modules
		####################################################################

		set +e # error mode off, just continue if a module fails
		echo -e " -- Running active modules..."
		run_active_modules

		####################################################################
		# lets send whatever we've gathered and run any pending jobs
		####################################################################

		echo -e "\n${bold} >> Sending report!${bold_end}\n"
		send_report
		run_delayed_jobs

		echo -e "\n$STRING_DONE"

	else
		echo -e "$STRING_NO_PROBLEM"
	fi
fi

delete_tmpdir
exit 0
