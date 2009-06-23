#!/bin/bash
####################################################################
# PREY Alerts Module - by Tomas Pollak (bootlog.org)
# URL : http://prey.bootlog.org
# License: GPLv3
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

