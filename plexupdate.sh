#!/bin/bash
#
# Script to automagically update Plex Media Server on Synology NAS
# Must be run as root to natively control running services.
#
# Author @michealespinola https://github.com/michealespinola
# https://github.com/michealespinola/plexupdate
#
# Forked from @martinorob https://github.com/martinorob
# https://github.com/martinorob/plexupdate/
#
# Example Task 'user-defined script': bash /var/services/homes/admin/scripts/bash/plex/plexupdate/plexupdate.sh
#
printf "\n"
printf "%s\n" "SYNO.PLEX UPDATER SCRIPT v2.0.0"
printf "\n"
#CHECK IF ROOT
if [ "$EUID" -ne 0 ]; then
  printf " %s\n" "This script MUST be run as root - exiting..."
  printf "\n"
  exit 1
fi
#SCRAPE DSM MAJOR VERSION AND CHECK
DSMVersion=$(more /etc.defaults/VERSION                             | grep -i 'productversion=' | cut -d"\"" -f 2)
dpkg --compare-versions "5" gt "$DSMVersion"
if [ $? -eq 0 ]; then
  printf " %s\n" "Plex Media Server requires DSM 5.0 minimum to install - exiting..."
  printf "\n"
  exit 1
fi
DSMVersion=$(echo        $DSMVersion-$(more /etc.defaults/VERSION   | grep -i 'buildnumber='    | cut -d"\"" -f 2))
DSMUpdateV=$(more /etc.defaults/VERSION                             | grep -i 'smallfixnumber=' | cut -d"\"" -f 2)
if [ -n "$DSMUpdateV" ]; then
  DSMVersion=$(echo $DSMVersion Update $DSMUpdateV)
fi
#SCRAPE SYNOLOGY HARDWARE MODEL
SynoHModel=$(more /proc/sys/kernel/syno_hw_version)
#SCRAPE SYNOLOGY CPU ARCHITECTURE FAMILY
ArchFamily=$(uname -m)
#SCRAPE SCRIPT FOLDER LOCATION
SPUSFolder=$(dirname "$0")
#SCRAPE PMS FOLDER LOCATION AND CREATE UPDATES DIR W/OLD FILE CLEANUP
PlexFolder=$(echo $PlexFolder | /usr/syno/bin/synopkg log "Plex Media Server")
PlexFolder=$(echo ${PlexFolder%/Logs/Plex Media Server.log})
PlexFolder=/$(echo ${PlexFolder#*/})
if [ -d "$PlexFolder/Updates" ]; then
  find "$PlexFolder/Updates" -type f -name "*.spk" -mtime +60 -delete
else
  mkdir "$PlexFolder/Updates"
fi
#SCRAPE PLEX ONLINE TOKEN
PlexOToken=$(cat "$PlexFolder/Preferences.xml" | grep -oP 'PlexOnlineToken="\K[^"]+')
#SCRAPE PLEXPASS CHANNEL FOR NEW VERSION INFO
DistroFile=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$PlexOToken")
DistroJson=$(curl -s $DistroFile)
NewVersion=$(echo $DistroJson | jq -r .nas.Synology.version)
#SCRAPE PUBLIC CHANNEL FOR NEW VERSION INFO
Distr1File=$(echo "https://plex.tv/api/downloads/5.json")
Distr1Json=$(curl -s $Distr1File)
Ne1Version=$(echo $Distr1Json | jq -r .nas.Synology.version)
#SCRAPE CURRENTLY RUNNING PMS VERSION
RunVersion=$(synopkg version "Plex Media Server")
#PRINT SOME DEBUG INFO
printf "%14s %s\n"           "Synology:" "$SynoHModel, $ArchFamily, DSM $DSMVersion"
printf "%14s %s\n"         "Script Dir:" "$SPUSFolder"
printf "%14s %s\n"           "Plex Dir:" "$PlexFolder"
printf "%14s %s\n"         "Plex Token:" "$PlexOToken"
printf "%14s %s\n"        "Running Ver:" "$RunVersion"
printf "%14s %s\n"       "PlexPass Ver:" "$NewVersion"
printf "%14s %s\n"         "Public Ver:" "$Ne1Version"
printf "\n"
#COMPARE VERSIONS
dpkg --compare-versions "$NewVersion" gt "$RunVersion"
if [ $? -eq 0 ]; then
  printf "%s\n" "NEWER VERSION FOUND:"
  printf "\n"
  DwnloadUrl=$(echo $DistroJson | jq -r ".nas.Synology.releases[] | .url" | grep -i "\-$ArchFamily\."); PackageSpk="${DwnloadUrl##*/}"
  printf "%14s %s\n"      "New Package:" "$PackageSpk"
  UpdateDate=$(curl -s -v --head $DwnloadUrl 2>&1 | grep -i '^< Last-Modified:' | cut -d" " -f 3-)
  UpdateDate=$(date --date "$UpdateDate" +'%s')
  TodaysDate=$(date --date "now" +'%s')
  UpdateEpoc=$((($TodaysDate-$UpdateDate)/86400))
  printf "%14s %s\n"     "Package Date:" "$(date --date='@1596567110')"
  printf "%14s %s\n"      "Package Age:" "$UpdateEpoc days"
  printf "\n"
  if [ $UpdateEpoc -ge 0 ]; then
    /bin/wget $DwnloadUrl -q -c -nc -P "$PlexFolder/Updates/"
    /usr/syno/bin/synopkg stop "Plex Media Server"
    /usr/syno/bin/synopkg install "$PlexFolder/Updates/$PackageSpk"
    /usr/syno/bin/synopkg start "Plex Media Server"
    NowVersion=$(synopkg version "Plex Media Server")
    dpkg --compare-versions "$NowVersion" gt "$RunVersion"
    printf "%14s %s\n"    "Update from:" "$RunVersion"
    printf "%14s %s"               "to:" "$NewVersion"
#REPORT UPDATE STATUS
    if [ $? -eq 0 ]; then
      printf " %s\n" "succeeded!"
      /usr/syno/bin/synonotify PKGHasUpgrade '{"%PKG_HAS_UPDATE%": "Plex Media Server update succeeded via Plex Update task"}'
      ExitStatus=1
    else
      printf " %s\n" "failed!"
      /usr/syno/bin/synonotify PKGHasUpgrade '{"%PKG_HAS_UPDATE%": "Plex Media Server update failed via Plex Update task"}'
      ExitStatus=1
    fi
  else
    printf "\n"
    printf " %s\n" "Update newer than 7 days - skipping..."
  fi
else
  printf " %s\n" "No new version found."
fi
printf "\n"
exit $ExitStatus
