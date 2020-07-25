#!/bin/bash
#
# Script to automagically update Plex Media Server on Synology NAS
# Must be run as root to natively control running services.
#
# @author @martinorob https://github.com/martinorob
# https://github.com/martinorob/plexupdate/
#
# @forked-author @michealespinola https://github.com/michealespinola
# https://github.com/michealespinola/plexupdate
#
# Example Task 'user-defined script': bash /var/services/homes/admin/scripts/bash/plex/plexupdate/plexupdate.sh
#
echo 
PlexFolder=$(echo $PlexFolder | /usr/syno/bin/synopkg log "Plex Media Server")
PlexFolder=$(echo ${PlexFolder%/Logs/Plex Media Server.log})
PlexFolder=/$(echo ${PlexFolder#*/})
PlexOToken=$(cat "$PlexFolder/Preferences.xml" | grep -oP 'PlexOnlineToken="\K[^"]+')
DistroFile=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$PlexOToken")
DistroJson=$(curl -s $DistroFile)
RunVersion=$(synopkg version "Plex Media Server")
NewVersion=$(echo $DistroJson | jq -r .nas.Synology.version)
mkdir "$PlexFolder/Updates" > /dev/null 2>&1
echo     " Running Version: $RunVersion"
echo     "  Online Version: $NewVersion"
dpkg --compare-versions "$NewVersion" gt "$RunVersion"
if [ $? -eq 0 ]; then
  echo 
  echo   "New version found!"
  echo 
  cpu=$(uname -m)
  if [ "$cpu" = "x86_64" ]; then
    DwnloadUrl=$(echo $DistroJson | jq -r ".nas.Synology.releases[1] | .url"); PackageSpk="${DwnloadUrl##*/}"
  else
    DwnloadUrl=$(echo $DistroJson | jq -r ".nas.Synology.releases[0] | .url"); PackageSpk="${DwnloadUrl##*/}"
  fi
  echo   "     New Package: $PackageSpk"
  UpdateDate=$(curl -s -v --head $DwnloadUrl 2>&1 | grep -i '^< Last-Modified:' | cut -d" " -f 3-)
  UpdateDate=$(date --date "$UpdateDate" +'%s')
  TodaysDate=$(date --date "now" +'%s')
  UpdateEpoc=$((($TodaysDate-$UpdateDate)/86400))
  echo   "    Package Date: $(date --date "@$UpdateDate")"
  echo   "     Package Age: $UpdateEpoc days"
  if [ $UpdateEpoc -ge 7 ]; then
    /bin/wget $DwnloadUrl -q -c -nc -P "$PlexFolder/Updates/"
    /usr/syno/bin/synopkg stop "Plex Media Server"
    /usr/syno/bin/synopkg install "$PlexFolder/Updates/$PackageSpk"
    /usr/syno/bin/synopkg start "Plex Media Server"
    NowVersion=$(synopkg version "Plex Media Server")
    dpkg --compare-versions "$NowVersion" gt "$RunVersion"
    if [ $? -eq 0 ]; then
      echo 
      echo "    Update from: $RunVersion"
      echo "             to: $NewVersion succeeded!"
      /usr/syno/bin/synonotify PKGHasUpgrade '{"%PKG_HAS_UPDATE%": "Plex Media Server update succeeded via Plex Update task"}'
      ExitStatus=1
    else
      echo 
      echo "    Update from: $RunVersion"
      echo "             to: $NewVersion failed!"
      /usr/syno/bin/synonotify PKGHasUpgrade '{"%PKG_HAS_UPDATE%": "Plex Media Server update failed via Plex Update task"}'
      ExitStatus=1
    fi
  else
    echo 
    echo   "Update newer than 7 days - skipping."
  fi
else
  echo 
  echo   "No new version found."
fi
echo 
exit $ExitStatus
