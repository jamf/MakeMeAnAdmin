#!/bin/bash

###############################################
# This script will provide temporary admin    #
# rights to a standard user right from self   #
# service. First it will grab the username of #
# the logged in user, elevate them to admin   #
# and then create a launch daemon that will   #
# count down from 30 minutes and then create  #
# and run a secondary script that will demote #
# the user back to a standard account. The    #
# launch daemon will continue to count down   #
# no matter how often the user logs out or    #
# restarts their computer.                    #
###############################################

#############################################
# find the logged in user and let them know #
#############################################

currentUser=$(who | awk '/console/{print $1}')
echo $currentUser

osascript -e 'display dialog "You now have administrative rights for 30 minutes. DO NOT ABUSE THIS PRIVILEGE..." buttons {"Make me an admin, please"} default button 1'

#########################################################
# write a daemon that will let you remove the privilege #
# with another script and chmod/chown to make 			#
# sure it'll run, then load the daemon					#
#########################################################

#Create the plist
sudo defaults write /Library/LaunchDaemons/removeAdmin.plist Label -string "removeAdmin"

#Add program argument to have it run the update script
sudo defaults write /Library/LaunchDaemons/removeAdmin.plist ProgramArguments -array -string /bin/sh -string "/Library/Application Support/JAMF/removeAdminRights.sh"

#Set the run inverval to run every 7 days
sudo defaults write /Library/LaunchDaemons/removeAdmin.plist StartInterval -integer 1800

#Set run at load
sudo defaults write /Library/LaunchDaemons/removeAdmin.plist RunAtLoad -boolean yes

#Set ownership
sudo chown root:wheel /Library/LaunchDaemons/removeAdmin.plist
sudo chmod 644 /Library/LaunchDaemons/removeAdmin.plist

#Load the daemon 
launchctl load /Library/LaunchDaemons/removeAdmin.plist
sleep 10

#########################
# make file for removal #
#########################

if [ ! -d /private/var/userToRemove ]; then
	mkdir /private/var/userToRemove
	echo $currentUser >> /private/var/userToRemove/user
	else
		echo $currentUser >> /private/var/userToRemove/user
fi

##################################
# give the user admin privileges #
##################################

/usr/sbin/dseditgroup -o edit -a $currentUser -t user admin

########################################
# write a script for the launch daemon #
# to run to demote the user back and   #
# then pull logs of what the user did. #
########################################

cat << 'EOF' > /Library/Application\ Support/JAMF/removeAdminRights.sh
if [[ -f /private/var/userToRemove/user ]]; then
	userToRemove=$(cat /private/var/userToRemove/user)
	echo "Removing $userToRemove's admin privileges"
	/usr/sbin/dseditgroup -o edit -d $userToRemove -t user admin
	rm -f /private/var/userToRemove/user
	launchctl unload /Library/LaunchDaemons/removeAdmin.plist
	rm /Library/LaunchDaemons/removeAdmin.plist
	log collect --last 30m --output /private/var/userToRemove/$userToRemove.logarchive
fi
EOF

exit 0
