# Description  

### Automatically update Plex Media Server on the Synology NAS platform

The intent of the fork of this script is to simplify its use to not require script variable editing or SSH access to the Synology NAS. Everything should be accomplishable via the most basic DSM web administration. This script is specifically for the official Synology package of Plex Media Server. It utilizes built-in tools to self-determine everything it needs to know about where Plex is located, how to update it, and to notify the system of updates or failures to update.  If Plex is installed and properly configured, you will not have to edit this script for any details about the installation location of Plex.

# How-To Example

## Script file placement

Download the script and place it into a location of your choosing. As an example, if you are using the "`admin`" account for system administration tasks, place the script within that accounts home folder such as in a nested folder location like this:

    \\SYNOLOGY\home\scripts\bash\plex\plexupdate\plexupdate.sh

-aka-

    \\SYNOLOGY\homes\admin\scripts\bash\plex\plexupdate\plexupdate.sh

## DSM Task Scheduler setup

1. Open the [DSM](https://www.synology.com/en-global/knowledgebase/DSM/help) web interface
1. Open the [Control Panel](https://www.synology.com/en-global/knowledgebase/DSM/help/DSM/AdminCenter/ControlPanel_desc)
1. Open [Task Scheduler](https://www.synology.com/en-global/knowledgebase/DSM/help/DSM/AdminCenter/system_taskscheduler)
   1. Click Create -> Scheduled Task -> User-defined script
   1. Enter Task: name as '`Plex Update`', and leave User: set to '`root`'
   1. Click Schedule tab and configure per your requirements
   1. Click Task Settings tab
   1. Enter 'User-defined script' as '`bash /var/services/homes/admin/scripts/bash/plex/plexupdate/plexupdate.sh`' if using the above script placement example. '`/var/services/homes`' is the base location of user home directories
1. Click OK

# To Do  

The code is currently hardcoded with a 7-day age requirement for installing the latest version as a bug/issue deterrent. This number value will soon be codifed as a parameter value. The intent of this fork is to never have to modify the base script for anything and to not have to SSH to anything either.

# Thanks!

Historical thanks to https://forums.plex.tv/u/j0nsplex !

# Script Logic Flow:

1. Identify "Plex Media Server" installation directory
1. Create default Plex "Updates" directory if it does not exist
1. Extract Plex Token from local Preferences file for use to lookup available updates
1. Lookup available updates and scrape JSON data
1. Compare currently running version information against latest online version
1. If new version exists and is older than 7 days - Install new version
1. Check if upgrade was successful and send appropriete notifcations
