#!/bin/bash
####################################################################
# PREY Report Module - by Tomas Pollak (bootlog.org)
# URL : http://prey.bootlog.org
# License: GPLv3
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
