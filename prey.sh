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
if [ "$net_status" == 0 ]; then
	echo "$STRING_TRY_TO_CONNECT"
	try_to_connect

	# ok, lets check again
	check_net_status
	if [ "$net_status" != "OK" ]; then
		echo " !! No network connection! Nothing to do, shutting down..."
		exit
	fi
fi

####################################################################
# if there's a URL in the config, lets see if it actually exists
# if it doesn't, the program will shut down gracefully
####################################################################

if [ -n "$url" ]; then
	echo "$STRING_CHECK_URL"
	check_url

	# ok, if the config actually contains something, it means Prey should do its magic
	# eventually the remote file can contain config params to modify certain behaviours in Prey
	if [ -n "$config" ]; then
		echo -e "$STRING_PROBLEM"
	else
		echo -e "$STRING_NO_PROBLEM"
		exit
	fi
fi

####################################################################
# ok, lets gather all the information
####################################################################

echo "$STRING_GET_IP"
get_public_ip

echo "$STRING_GET_LAN_IP"
get_internal_ip

echo "$STRING_GET_MAC_AND_WIFI"
get_network_info

# traceroute=`which traceroute` <-- disabled since its TOO DAMN SLOW!
if [ -n "$traceroute" ]; then
	echo "$STRING_TRACE"
	trace_route
fi

echo "$STRING_UPTIME_AND_PROCESS"
get_uptime_and_processes

echo "$STRING_MODIFIED_FILES"
get_modified_files

echo "$STRING_ACTIVE_CONNECTIONS"
get_active_connections

echo "$STRING_WRITE_EMAIL"
write_email

echo "$STRING_TAKE_IMAGE"
get_images
echo "$STRING_TAKE_IMAGE_DONE"

####################################################################
# all set, lets send the email
####################################################################

echo "$STRING_SENDING_EMAIL"

# lets clean the vars in case we couldn't get the images
if [ ! -e "$picture" ]; then
	picture=''
fi

if [ ! -e "$screenshot" ]; then
	screenshot=''
# else
	# should we compress the screenshot? (faster email sending)
	# compress_screenshot
fi

send_email

echo "$STRING_REMOVE_EVIDENCE"
remove_evidence

####################################################################
# post email stuff, wallpaper and message alerts
####################################################################

if [ $alertwallpaper == 'y' ]; then
	echo "$STRING_CHANGE_WALLPAPER"
	# we need the full path to the files (and we'll asume the script is being run from prey's folder)
	wallpaper=`pwd`/$wallpaper
	change_wallpaper
fi

if [ $alertuser == 'y' ]; then
	echo "$STRING_SHOW_ALERT"
	alert_user
fi

# should we drop him out of his X session?
if [ $killx == "y" ]; then
	echo "$STRING_XKILL"
	kill_x
fi

# this is the end, my only friend
echo -e "$STRING_DONE"
