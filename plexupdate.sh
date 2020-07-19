#!/bin/bash
#
# Script to automagically update Plex Media Server on Synology NAS
#
# Must be run as admin.
#
# @author @martinorob https://github.com/martinorob
# https://github.com/martinorob/plexupdate/
#
# @forked-author @michealespinola https://github.com/michealespinola
# https://github.com/michealespinola/plexupdate
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
echo "Current Version: $curversion"
newversion=$(echo $jq | jq -r .nas.Synology.version)
echo " Latest Version: $newversion"
dpkg --compare-versions "$newversion" gt "$curversion"
if [ $? -eq "0" ]
then
echo 
echo New version found..
/usr/syno/bin/synonotify PKGHasUpgrade '{"[%HOSTNAME%]": $(hostname), "[%OSNAME%]": "Synology", "[%PKG_HAS_UPDATE%]": "Plex", "[%COMPANY_NAME%]": "Synology"}'
cpu=$(uname -m)
if [ "$cpu" = "x86_64" ]; then
 url=$(echo $jq | jq -r ".nas.Synology.releases[1] | .url")
else
 url=$(echo $jq | jq -r ".nas.Synology.releases[0] | .url")
fi
/bin/wget $url -P "$PLEX/Updates/plexupdate/"
/usr/syno/bin/synopkg install "$PLEX/Updates/plexupdate/*.spk"
sleep 30
/usr/syno/bin/synopkg start "Plex Media Server"
rm -rf "$PLEX/Updates/plexupdate/*"
else
echo 
echo No new version found..
fi
exit
