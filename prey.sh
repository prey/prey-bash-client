#!/bin/bash
####################################################################
# PREY - by Tomas Pollak (bootlog.org)
# URL : http://prey.bootlog.org
# License: GPLv3
####################################################################

version='0.2.5'
base_path=`dirname $0`

. $base_path/config

if [ ! -e "lang/$lang" ]; then # fallback to english in case the lang is missing
	lang='en'
fi
. $base_path/lang/$lang

# valid unames: Linux, Darwin, FreeBSD, CygWin?
# we also set it to lowercase
os=`uname | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"`
. $base_path/platform/base
. $base_path/platform/$os

echo -e "\E[36m$STRING_START\E[0m"

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

if [ -n "$url" ]; then
	echo "$STRING_CHECK_URL"
	check_status

	if [ $status == '200' ]; then
		echo -e "$STRING_PROBLEM"
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

