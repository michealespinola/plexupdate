#!/bin/bash

# Script to automagically update Plex Media Server on Synology NAS
#
# Must be run as root.
#
# @author @martinorob https://github.com/martinorob
# https://github.com/martinorob/plexupdate/

<<<<<<< HEAD
#!/bin/bash
mkdir -p /tmp/plex/ > /dev/null 2>&1
token=$(cat /volume1/Plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml | grep -oP 'PlexOnlineToken="\K[^"]+')
=======
# Variables
declare VOLUME="/volume1"

# Script
mkdir ${VOLUME}/plextemp/ > /dev/null 2>&1
token=$(cat ${VOLUME}/Plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml | grep -oP 'PlexOnlineToken="\K[^"]+')
>>>>>>> b2a392151dc7cbd17fb14637e4e4ffcc60d71dd4
url=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$token")
jq=$(curl -s ${url})
newversion=$(echo $jq | jq -r .nas.Synology.version)
echo New Ver: $newversion
curversion=$(synopkg version "Plex Media Server")
echo Cur Ver: $curversion
if [ "$newversion" != "$curversion" ]
then
echo New Vers Available
/usr/syno/bin/synonotify PKGHasUpgrade '{"[%HOSTNAME%]": $(hostname), "[%OSNAME%]": "Synology", "[%PKG_HAS_UPDATE%]": "Plex", "[%COMPANY_NAME%]": "Synology"}'
<<<<<<< HEAD
CPU=$(uname -m)
url=$(echo "${jq}" | jq -r '.nas.Synology.releases[] | select(.build=="linux-'"${CPU}"'") | .url')
/bin/wget $url -P /tmp/plex/
/usr/syno/bin/synopkg install /tmp/plex/*.spk
sleep 30
/usr/syno/bin/synopkg start "Plex Media Server"
rm -rf /tmp/plex/*
=======
cpu=$(uname -m)
if [ "$cpu" = "x86_64" ]; then
url=$(echo $jq | jq -r ".nas.Synology.releases[1] | .url")
else
 url=$(echo $jq | jq -r ".nas.Synology.releases[0] | .url")
fi
/bin/wget $url -P ${VOLUME}/tmp/plex/
/usr/syno/bin/synopkg install ${VOLUME}/tmp/plex/*.spk
sleep 30
/usr/syno/bin/synopkg start "Plex Media Server"
rm -rf ${VOLUME}/tmp/plex/*
>>>>>>> b2a392151dc7cbd17fb14637e4e4ffcc60d71dd4
else
echo No New Ver
fi
exit
