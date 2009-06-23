#!/bin/bash
####################################################################
# PREY - by Tomas Pollak (bootlog.org)
# URL : http://prey.bootlog.org
# License: GPLv3
####################################################################

version='0.2'
. ./config

if [ ! -e "lang/$lang" ]; then # fallback to english in case the lang is missing
	lang='en'
fi
. lang/$lang

# valid unames: Linux, Darwin, FreeBSD, CygWin?
# we also set it to lowercase
os=`uname | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"`
. platform/base
. platform/$os

echo -e "\E[36m$STRING_START\E[0m"

####################################################################
# lets check if we're actually connected
# if we're not, lets try to connect to a wifi access point
####################################################################

check_net_status
if [ $net_status == 0 ]; then
	echo "$STRING_TRY_TO_CONNECT"
	try_to_connect

	# ok, lets check again
	check_net_status
	if [ $net_status == 0 ]; then
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

	if [ $activate == 1 ]; then
		echo -e "$STRING_PROBLEM"
		parse_response
	else
		echo -e "$STRING_NO_PROBLEM"
		exit
	fi
fi

####################################################################
# ok what shall we do then?
# for now lets run every module with an executable run.sh script
####################################################################

for module_path in `find modules -maxdepth 1 -mindepth 1 -type d`; do

	if [ -x "$module_path/run.sh" ]; then

		# if there's a language file, lets run it
		if [ -f $module_path/lang/$lang ]; then
		. $module_path/lang/$lang
		elif [ -f $module_path/lang/$lang ];
		. $module_path/lang/en
		fi

		# if there's a config file, lets run it as well
		if [ -f $module_path/config ]; then
			. $module_path/config
		fi

		# now, go!
		. $module_path/run.sh
	fi

done

# this is the end, my only friend
echo -e "$STRING_DONE"
