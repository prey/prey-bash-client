#!/bin/bash
####################################################################
# Prey Client - by Tomas Pollak (bootlog.org)
# URL: http://preyproject.com
# License: GPLv3
####################################################################

# set -u
# set -e

PATH=platform/windows/bin:$PATH # for windows
readonly base_path=`dirname $0`

####################################################################
# base files inclusion
####################################################################

. $base_path/version
. $base_path/config
if [ ! -f "lang/$lang" ]; then # fallback to english in case the lang is missing
	lang='en'
fi
. $base_path/lang/$lang
. $base_path/core/base
. $base_path/platform/$os/core

echo -e "\E[36m$STRING_START ### `date`\E[0m\n"

if [ "$1" == "-t" ]; then
	echo -e "\033[1m -- TEST MODE ENABLED. WON'T SEND DATA!\033[0m\n"
	. $base_path/config.test 2> /dev/null
	test_mode=1
fi

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

	# ok, lets check again
	check_net_status
	if [ $connected == 0 ]; then
		echo "$STRING_NO_CONNECT_TO_WIFI"
		exit
	fi
fi

####################################################################
# if there's a URL in the config, lets see if it actually exists
# if it doesn't, the program will shut down gracefully
####################################################################

if [ -n "$check_url" ]; then
	echo "$STRING_CHECK_URL"

	check_status
	parse_headers
	process_response

	echo " -- Got status code $status."

	if [ "$status" == "$missing_status_code" ]; then
		echo -e "\n$STRING_PROBLEM"
	else
		echo -e "\n$STRING_NO_PROBLEM"
		exit 0
	fi
fi

####################################################################
# ok what shall we do then?
# for now lets run every module with an executable run.sh script
####################################################################

# lets create our ultramegasecret temp dir
mkdir -p $tmpdir 2> /dev/null
chmod 700 $tmpdir

set +e # error mode off, just continue if a module fails
echo -e " -- Running active modules..."
run_active_modules

####################################################################
# lets send whatever our modules have gathered
####################################################################

echo -e " -- Sending report..."
send_report
run_delayed_jobs

echo -e "$STRING_DONE"
rm -Rf $tmpdir

exit 0
