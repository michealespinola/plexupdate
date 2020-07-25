# Description  
Automatically update Plex Media Server on the Synology NAS platform

# How-To Example

## Script file placement

Download the script and put it into a location of your choosing. As an example, if you are using the "`admin`" account for system administration tasks, place the script within that account home folder such in a nested folder location like at:

    \\SYNOLOGY\home\scripts\bash\plex\plexupdate\plexupdate.sh

-or-

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

Historical thanks to https://forums.plex.tv/u/j0nsplex
