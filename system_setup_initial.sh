#!/bin/bash
##
## 10.10/10.11 Initial system setup script
## Date Created: 2-6-13
## Last Modified: 03-20-2015
##

## Check if script has already run
if [ -e /Library/Receipts/InitialSetup.pkg ]
     then
     	/bin/echo “*** Setup script has alreay been ran...”
        exit 0
     fi

## Log to debug file
set –xv; exec 1>/Library/Logs/IntegerInitialSetup.txt 2>&1
/bin/echo "*** Initial setup script running..."
/bin/date

## Update dyld library cache
/usr/bin/update_dyld_shared_cache -force
/bin/echo "*** Updating dyld library cache..."

## Prevent iCloud login from launching
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool true
defaults write /System/Library/User\ Template/Non_localized/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool true
/bin/echo "*** Disabling iCloud setup..."


## Disable Time Machine disk prompts
defaults write /Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
/bin/echo "*** Disabling Time Machine disk prompts..."

## Disable Fast User Switching
defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool false
/bin/echo "*** Disabling Fast User Switching..."

## Disable Bluetooth
defaults write /Library/Preferences/com.apple.Bluetooth.plist ControllerPowerState -bool false
/bin/echo "*** Disabling Bluetooth..."

## Setting software update server
defaults write /Library/Preferences/com.apple.SoftwareUpdate CatalogURL http://betatech.integer.com:8088/index.sucatalog
/bin/echo "*** Software update server set to Betatech..."

## Disable .DS_Store file creation on network volumes
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.desktopservices DSDontWriteNetworkStores true
/bin/echo "*** Disabling .DS_Store file creations for network volumes..."

## Enable screensaver unlock by admin accounts
/usr/libexec/PlistBuddy -c 'Set :rights:system.login.screensaver:comment "The owner or any administrator can unlock the screensaver."' /etc/authorization
    if grep -q "ruser" /etc/pam.d/screensaver
        then
            sed -i.bak '/ruser/ d' /etc/pam.d/screensaver
        fi
/bin/echo "*** Enabling ability to unlock screensaver with any admin account..."

## Enable AirDrop on all interfaces
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1
/bin/echo "*** Airdrop enabled..."

## Create main administrator account
dscl . create /Users/integeradmin
dscl . create /Users/integeradmin UserShell /bin/bash
dscl . create /Users/integeradmin RealName "Integer Admin"
dscl . create /Users/integeradmin UniqueID 401
dscl . create /Users/integeradmin PrimaryGroupID 80
dscl . create /Users/integeradmin NFSHomeDirectory /Users/integeradmin
dscl . passwd /Users/integeradmin "temppass"
dscl . append /Groups/admin GroupMembership admin
/bin/echo "*** Integer Admin account created with temporary password..."

## Enable SSH
/usr/sbin/systemsetup -setremotelogin on
/bin/echo "*** SSH enabled..."

## Start ARD Agent
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users admin -privs -all -restart -agent
/bin/echo "*** Starting ARD agent..."

## Add User to CUPS
##/usr/sbin/dseditgroup -o edit -n /Local/Default -u admin -P ‘"****"’ -a everyone -t group lpadmin
##/bin/echo "***all users added to cups***"

## Set GateKeeper to allow apps to launch from anywhere
spctl --master-disable
/bin/echo "*** Disabling GateKeeper..."

## Write dummy receipt
touch /Library/Receipts/InitialSetup.pkg
/bin/echo "*** Writing imaging receipt..."

## Show username and password field at login screen
defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -boolean true
/bin/echo "*** Showing username and password fields at login..."

## Enable location services
launchctl unload /System/Library/LaunchDaemons/com.apple.locationd.plist
uuid=`/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | cut -c22-57`
defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.$uuid LocationServicesEnabled -int 1
chown -R _locationd:_locationd /var/db/locationd
launchctl load /System/Library/LaunchDaemons/com.apple.locationd.plist
/bin/echo "*** Enabling location services..."

## Allow click thru on login screen to see IP, Host Name, OS version
defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
/bin/echo "*** Setting click thru clock on login window..."

## Expanded print dialog by default
defaults write /Library/Preferences/.GlobalPreferences PMPrintingExpandedStateForPrint2 -bool true
/bin/echo "*** Setting expanded print dialog by default..."

## Show items on Desktop
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
/bin/echo "*** Mounted volumes shown on Desktop..."

## Power management
model=`system_profiler SPHardwareDataType | grep 'Model Name:' | awk '{ print $3 }'`
if [[ $model == "MacBook" ]]; then
    pmset -b sleep 60 disksleep 0 displaysleep 30 halfdim 1
    pmset -c sleep 0 disksleep 0 displaysleep 60 halfdim 1
  else
    pmset sleep 180 disksleep 0 displaysleep 60 halfdim 1
fi
/bin/echo "*** Power management settings configured..."

## Setting system time
systemsetup -setusingnetworktime on
systemsetup -setnetworktimeserver time.apple.com
/bin/echo "*** System time set..."

## Disable save window state at logout
defaults write com.apple.loginwindow 'TALLogoutSavesState' -bool false
/bin/echo "*** Save window state at logout disabled..."

## Disable external accounts
defaults write /Library/Preferences/com.apple.loginwindow EnableExternalAccounts -bool false
/bin/echo "*** Disabling login with external accounts..."

## Login screen disclaimer
#defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This computer and its contents are property of The Integer Group. By logging in, you accept the terms of usage set forth in the Employee Handbook. Any unauthorized use of this system is strictly prohibited. For assistance, please contact the IT Help Desk at 303-393-3030."
#bin/echo "*** Login screen disclaimer set..."

## Check and install OS software updates
/bin/echo "*** Installing OS updates..."
softwareupdate -i -a

## Echo a status
/bin/echo "*** Initial setup complete."
/bin/date