#!/bin/sh

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

minutes_to_allow_admin=30

currentUser=$(who | awk '/console/{print $1}')
echo ${currentUser}

try osascript -e 'display dialog "You now have administrative rights for 30 minutes. DO NOT ABUSE THIS PRIVILEGE..." buttons {"Make me an admin, please"} default button 1'

#########################################################
# write a daemon that will let you remove the privilege #
# with another script and chmod/chown to make                   #
# sure it'll run, then load the daemon                                  #
#########################################################


#Create the plist
try sudo defaults write /Library/LaunchDaemons/removeAdmin.plist Label -string "removeAdmin"

#Add program argument to have it run the update script
try sudo defaults write /Library/LaunchDaemons/removeAdmin.plist ProgramArguments -array -string /bin/sh -string "/Library/Application Support/JAMF/removeAdminRights.sh"

# start the daemon after the specified time
admin_seconds=$(expr ${minutes_to_allow_admin} \* 60)
try sudo defaults write /Library/LaunchDaemons/removeAdmin.plist StartInterval -integer ${admin_seconds}

#Set run at load
try sudo defaults write /Library/LaunchDaemons/removeAdmin.plist RunAtLoad -boolean yes

#Set ownership
try sudo chown root:wheel /Library/LaunchDaemons/removeAdmin.plist
try sudo chmod 644 /Library/LaunchDaemons/removeAdmin.plist

#Load the daemon 
try launchctl load /Library/LaunchDaemons/removeAdmin.plist
sleep 10

#########################
# make file for removal #
#########################

if [ ! -d /private/var/userToRemove ]; then
    rm -f /private/var/userToRemove
    mkdir -p /private/var/userToRemove
fi
echo ${currentUser} >> /private/var/userToRemove/user

##################################
# give the user admin privileges #
##################################

try /usr/sbin/dseditgroup -o edit -a ${currentUser} -t user admin

########################################
# write a script for the launch daemon #
# to run to demote the user back and   #
# then pull logs of what the user did. #
########################################

cat << 'EOF' > /Library/Application\ Support/JAMF/removeAdminRights.sh
#!/bin/sh
date=$(date +%Y-%m-%d_%H-%M-%S)
if [ -f /private/var/userToRemove/user ]; then
    for userToRemove in $(cat /private/var/userToRemove/user); do
        echo "Removing ${userToRemove}'s admin privileges"
        /usr/sbin/dseditgroup -o edit -d ${userToRemove} -t user admin
        log collect --last 30m --output /private/var/userToRemove/${userToRemove}-${date}.logarchive
    done

    rm -f /private/var/userToRemove/user
    launchctl unload /Library/LaunchDaemons/removeAdmin.plist
    rm /Library/LaunchDaemons/removeAdmin.plist
fi
EOF

exit 0
