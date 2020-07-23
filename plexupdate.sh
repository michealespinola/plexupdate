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
#
# Variables (Get location of Plex automagically and declare it as PLEX)
PLEX=$(echo $PLEX | /usr/syno/bin/synopkg log "Plex Media Server")
PLEX=$(echo ${PLEX%/Logs/Plex Media Server.log})
PLEX=/$(echo ${PLEX#*/})
#
# Script
echo 
mkdir "$PLEX/Updates" > /dev/null 2>&1
token=$(cat "$PLEX/Preferences.xml" | grep -oP 'PlexOnlineToken="\K[^"]+')
url=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$token")
jq=$(curl -s ${url})
curversion=$(synopkg version "Plex Media Server")
newversion=$(echo $jq | jq -r .nas.Synology.version)
echo "      Plex Token: $token"
echo 
echo " Running Version: $curversion"
echo "  Latest Version: $newversion"
dpkg --compare-versions "$newversion" gt "$curversion"
if [ $? -eq 0 ]; then
  echo 
  echo New version found...
  echo 
  /usr/syno/bin/synonotify PKGHasUpgrade '{"[%HOSTNAME%]": $(hostname), "[%OSNAME%]": "Synology", "[%PKG_HAS_UPDATE%]": "Plex", "[%COMPANY_NAME%]": "Synology"}'
  cpu=$(uname -m)
if [ "$cpu" = "x86_64" ]; then
  url=$(echo $jq | jq -r ".nas.Synology.releases[1] | .url"); package="${url##*/}"
else
  url=$(echo $jq | jq -r ".nas.Synology.releases[0] | .url"); package="${url##*/}"
fi
  echo "     New Version: $newversion"
  echo "     New Package: $package"
  echo 
  /bin/wget $url -c -nc -P "$PLEX/Updates/"
  /usr/syno/bin/synopkg stop "Plex Media Server"
  /usr/syno/bin/synopkg install "$PLEX/Updates/$package"
  /usr/syno/bin/synopkg start "Plex Media Server"
  nowversion=$(synopkg version "Plex Media Server")
  dpkg --compare-versions "$nowversion" gt "$curversion"
  if [ $? -eq 0 ]; then
    echo 
    echo "   Upgrade from: $curversion"
    echo "             to: $newversion succeeded!"
    echo 
  else
    echo 
    echo "   Upgrade from: $curversion"
    echo "             to: $newversion failed!"
    echo 
  fi
else
  echo 
  echo No new version found.
  echo 
fi
exit
