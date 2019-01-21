Make Me an Admin!

This script, when run, will allow a standard user to upgrade themselves to an admin for 30 minutes and then will grab a snapshot of the logs for the past 30 minutes as well so you can track what they did. 

The script will create a launch daemon to take care of demoting the user so that no matter how many times they log out or shut down, after 30 minutes of uptime, a script will be run to remove their admin privileges. 

It is recommended to push this script as a policy to self service to run only once per day.

Edits: If you wish to tailor the script to your own needs, here is where to make the changes.

User Prompt: Line 24 | Plain text
Default Message: You now have administrative rights for 30 minutes. DO NOT ABUSE THIS PRIVILEGE... 
Default Button: "Make me an admin, please!"

Time Frame for Admin Rights: Line 39 | Integer in seconds
Default: 1800 (30 minutes)

Time Frame for logs to be pulled:  Line 82 | String after the "--last" flag in minutes
Default: 30m

Location to save logs: line 82 | String after "--output" flag, must be valid directory
Default: /private/var/userToRemove/$userToRemove.logarchive