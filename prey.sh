#!/bin/bash
####################################################################
# Prey - by Tomas Pollak (bootlog.org)
# URL: http://preyproject.com
# License: GPLv3
####################################################################

running_prey=`ps aux | grep "prey.sh" | grep -v grep | wc -l`
if [[ "$running_prey" -gt 2 && "$1" != "-f" ]]; then # prey is already running

	echo ' !! Prey is already running! Kill the other process or run with -f to force execution.'
	exit

fi

version='0.2.5'
base_path=`dirname $0`
start_time=`date +"%F %T"`

. $base_path/config

if [ ! -e "lang/$lang" ]; then # fallback to english in case the lang is missing
	lang='en'
fi
. $base_path/lang/$lang

# we  to fetch the OS-specific methods
os=`uname | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"`
. $base_path/platform/base
. $base_path/platform/$os

echo -e "\E[36m$STRING_START\E[0m"

if [ "$1" == "-t" ]; then
	echo -e "\033[1m -- TEST MODE ENABLED. WON'T CHECK URL OR SEND STUFF!\033[0m\n"
	test_mode=1
	check_url=''
fi

####################################################################
# lets check if we're actually connected
# if we're not, lets try to connect to a wifi access point
####################################################################

check_net_status
if [ $connected == 0 ]; then
	echo "$STRING_TRY_TO_CONNECT"
	try_to_connect

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

	if [ "$status" == '200' ]; then
		echo -e "$STRING_PROBLEM"
		parse_headers
		process_response
	else
		echo -e "$STRING_NO_PROBLEM"
		exit
	fi
fi

####################################################################
# ok what shall we do then?
# for now lets run every module with an executable run.sh script
####################################################################

echo -e " -- Running active modules..."
run_active_modules
echo -e "$STRING_DONE"

