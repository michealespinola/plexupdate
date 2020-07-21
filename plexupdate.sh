#!/bin/bash
#
# Script to automagically update Plex Media Server on Synology NAS
#
# Must be run as root to natively control running services.
#
# @author @martinorob https://github.com/martinorob
# https://github.com/martinorob/plexupdate/
#
# @forked-author @michealespinola https://github.com/michealespinola
# https://github.com/michealespinola/plexupdate
# NEW VARIABLES IN CAPS BECAUSE I AM A CHILD
#
# Variables
VOLUME="/volume1"
PLEX="$VOLUME/Plex/Library/Application Support/Plex Media Server"
#
# Script
mkdir "$PLEX/Updates/plexupdate" > /dev/null 2>&1
token=$(cat "$PLEX/Preferences.xml" | grep -oP 'PlexOnlineToken="\K[^"]+')
url=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$token")
jq=$(curl -s ${url})
curversion=$(synopkg version "Plex Media Server")
echo 
echo "Current Version: $curversion"
newversion=$(echo $jq | jq -r .nas.Synology.version)
echo " Latest Version: $newversion"
dpkg --compare-versions "$newversion" gt "$curversion"
if [ $? -eq "0" ]
then
echo 
echo New version found...
echo 
/usr/syno/bin/synonotify PKGHasUpgrade '{"[%HOSTNAME%]": $(hostname), "[%OSNAME%]": "Synology", "[%PKG_HAS_UPDATE%]": "Plex", "[%COMPANY_NAME%]": "Synology"}'
cpu=$(uname -m)
if [ "$cpu" = "x86_64" ]; then
  url=$(echo $jq | jq -r ".nas.Synology.releases[1] | .url"); FILE="${url##*/}"
else
  url=$(echo $jq | jq -r ".nas.Synology.releases[0] | .url"); FILE="${url##*/}"
fi
echo "    New Version: $newversion"
echo "       New File: $FILE"
echo 
/bin/wget $url -c -nc -P "$PLEX/Updates/plexupdate/"
/usr/syno/bin/synopkg stop "Plex Media Server"
/usr/syno/bin/synopkg install "$PLEX/Updates/plexupdate/$FILE"
/usr/syno/bin/synopkg start "Plex Media Server"
# rm -rf "$PLEX/Updates/plexupdate/*"
else
echo 
echo No new version found.
echo 
fi
exit
