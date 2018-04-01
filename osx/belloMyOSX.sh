#!/bin/bash
# shellcheck disable=SC2034
# =============================================================================
#   FileName: belloMyOSX.sh
#     Author: marslo.jiao@gmail.com
#    Created: 2017-10-30 16:38:58
# LastChange: 2018-02-27 18:07:51
# =============================================================================

HOSTNAME="iMarslo"
TIMEZONE="Asia/Chongqing"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
# 'systemsetup -listtimezones'

modifierNoOp=0
modifierMissionCtl=2
modifierApplicationWindows=3
modifierDesktop=4
modifierStartScreenSaver=5
modifierDisableScreenSaver=6
modifierDashboard=7
modifierDisplayToSleep=10
modifierLaunchpad=11

modifierNone=0
modifierShift=131072
modifierControl=262144
modifierOption=524288
modifierCmd=1048576

ARTIFACTORYHOST="www.mycompany.com"
ARTIFACTORYURL="http://${ARTIFACTORYHOST}/artifactory"

function basicEnvSetup(){
  sudo scutil --set ComputerName $HOSTNAME
  sudo scutil --set HostName $HOSTNAME
  sudo scutil --set LocalHostName $HOSTNAME
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string $HOSTNAME
  sudo killall -HUP mDNSResponder
  sudo killall mDNSResponderHelper
  sudo dscacheutil -flushcache

  # sudo systemsetup -gettimezone
  sudo /usr/sbin/systemsetup -settimezone $TIMEZONE
  # sudo systemsetup -getnetworktimeserver
  sudo /usr/sbin/systemsetup -setnetworktimeserver "time.asia.apple.com"
  # sudo systemsetup -getusingnetworktime
  sudo /usr/sbin/systemsetup -setusingnetworktime on

  # Never go into computer sleep mode
  sudo systemsetup -setcomputersleep Off

  # disable ipv6
  networksetup -setv6off Ethernet
  networksetup -setv6off Wi-Fi


  sysctl user.cs_path
  sudo sysctl -w user.cs_path=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
  sudo launchctl config user path /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
  # sudo shutdown -r now

  launchctl getenv PATH
  cat /etc/paths

  [ ! -d "$HOME/.vim/cache" ] && mkdir -p "$HOME/.vim/cache"

  cat >> $HOME/.marslo/.bello_mac << EOF

# Setup by script
[ -f /usr/local/bin/screenfetch ] && /usr/local/bin/screenfetch

GRADLE_HOME="/opt/gradle/gradle-3.3"
M2_HOME="/opt/maven/apache-maven-3.3.9"
M2=\$M2_HOME/bin
MAVEN_OPTS="-Xms512m -Xmx1G"
GNUBINHOME="/usr/local/opt/coreutils/libexec/gnubin"
GNUMANHOME="/usr/local/opt/coreutils/libexec/gnuman"
PATH=\$GNUBINHOME:\$M2:\$GRADLE_HOME/bin:\$PATH:"/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
MANPATH=$GNUMANHOME:$MANPATH
CLASSPATH=".:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar"

export CLASSPATH GRADLE_HOME M2_HOME M2 MAVEN_OPTS PATH MANPATH
EOF
}

function setupStartups(){
[ ! -d "$HOME/Library/LaunchAgents/" ] && mkdir -p ~/Library/LaunchAgents/

cat << 'EOF' > ~/Library/LaunchAgents/i.marslo.mocjackd.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>i.marslo.mocjackd</string>
        <key>WorkingDirectory</key>
        <string>/Users/marslo/</string>
        <key>ProgramArguments</key>
        <array>
            <string>/usr/local/bin/jackd</string>
            <string>-d</string>
            <string>coreaudio</string>
        </array>
        <key>EnableGlobbing</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
    </dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/i.marslo.mocjackd.plist
launchctl load ~/Library/LaunchAgents/i.marslo.mocgrowl.plist
sudo launchctl unload -w /Library/LaunchDaemons/at.obdev.littlesnitchd.plist

[ ! -d /usr/local/bin/ ] && mkdir -p /usr/local/bin/
[ ! -d $HOME/.marslo/bin ] && mkdir -p $HOME/.marslo/bin

ln -sf $PWD/addRoute.osx.sh $HOME/.marslo/bin/addd
ln -sf $PWD/removeRoute.sh $HOME/.marslo/bin/remr

ln -sf $HOME/.marslo/bin/addr /usr/local/bin/addr
ln -sf $HOME/.marslo/bin/remr /usr/local/bin/remr

# sudo cp ./addRoute.osx.sh /usr/local/bin/addr
# sudo cp ./removeRoute.sh /usr/local/bin/remr

cat > ~/Library/LaunchAgents/i.marslo.addroute.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>i.marslo.addroute</string>
        <key>WorkingDirectory</key>
        <string>/Users/marslo</string>
        <key>ProgramArguments</key>
        <array>
            <string>/Users/marslo/mywork/job/code/marslo/backups/1.marslo_env/belloMarslo/addRoute.sh</string>
            <!-- <string>/Users/marslo/.marslo/bin/addroute.fake.sh</string> -->
        </array>
        <key>EnableGlobbing</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
    </dict>
</plist>
EOF

plutil ~/Library/LaunchAgents/i.marslo.addroute.plist
sudo chown -R root:wheel ~/Library/LaunchAgents/i.marslo.addroute.plist
sudo launchctl load ~/Library/LaunchAgents/i.marslo.addroute.plist
sudo launchctl list | grep route
}

############
## System ##
############
function setupSystemDefaults(){
  # Setup login window text
  sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "Awesome Marslo !!"
  # Set language
  defaults write -g AppleLanguages -array 'en'
  # Set measurement units
  defaults write -g AppleMeasurementUnits -string 'Centimeters'
  # Hide battery percentage from the menu bar
  defaults write com.apple.menuextra.battery ShowPercent -string 'NO'
  # disable dashboard
  defaults write com.apple.dashboard mcx-disabled -boolean YES
  # Disable system sleep
  sudo systemsetup -setcomputersleep Never

  # Press repet key
  defaults write -g ApplePressAndHoldEnabled -bool false
  # Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
  # Keyboard -> Adjust keyboard brightness in low light
  defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Automatic Keyboard Enabled" -bool true
  defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Keyboard Dim Time" -int 300
  # Keyboard Layout
  defaults write /Library/Preferences/com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID "com.apple.keylayout.ABC"
  defaults write /Library/Preferences/com.apple.HIToolbox AppleDefaultAsciiInputSource -dict InputSourceKind "Keyboard Layout" "KeyboardLayout ID" -int 252 "KeyboardLayout Name" ABC
  # Turn autocorrect on
  defaults write -g NSAutomaticSpellingCorrectionEnabled -bool true

  # Show basic system info at the login screen
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
  # Enable tap to click (Trackpad)
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  # Map bottom right Trackpad corner to right-click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
  # Enable the debug menu in iCal
  defaults write com.apple.iCal IncludeDebugMenu -bool true
  # Disable resume system-wide
  defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
  # make textEditor to plain text
  defaults write com.apple.TextEdit RichText -int 0
  # Make the save panel expanded by default
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  # Save screenshots to the Desktop
  defaults write com.apple.screencapture location -string "$HOME/Desktop"
  # Save screenshots as PNGs
  defaults write com.apple.screencapture type -string 'png'

  # turn off use disk for time machine
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool YES

  killall "SystemUIServer"
}

###############
## Developer ##
###############
function setupDevDefaults(){
  # Only use UTF-8 in Terminal.app
  defaults write com.apple.terminal StringEncodings -array 4
  # enable SSH
  sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
  # Disable the “Are you sure you want to open this application?” dialog
  defaults write com.apple.LaunchServices LSQuarantine -bool false
  # enable VNC
  # sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -clientopts -setvnclegacy -vnclegacy yes -clientopts -setvncpw -vncpw PutYourOwnPasswordHere -restart -agent -privs -all
}

##############
## AppStore ##
##############
function setupAppstoreDefaults(){
  # Check update daily
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
  # Download newly available updates in background
  defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
  # Install System data files and security updates
  defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
  # Enable automatic update check
  defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

  killall "App Store"
}


############
## Safari ##
############
function setupSafariDefaults(){
  # set safari default font size
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2MinimumFontSize -int 18
  # Enable Safari’s debug menu
  defaults write com.apple.Safari IncludeDebugMenu -bool true
  # Remove useless icons from Safari’s bookmarks bar
  defaults write com.apple.Safari ProxiesInBookmarksBar "()"
  # Enable the 'Develop' menu and the 'Web Inspector'
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
  defaults write com.apple.Safari IncludeDevelopMenu -bool true
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  # Set home page to 'about:blank'
  defaults write com.apple.Safari HomePage -string 'about:blank'
  # Enable 'Debug' menu
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
  # Show bookmarks bar by default
  defaults write com.apple.Safari ShowFavoritesBar -bool true
  # Show the full URL in the address bar
  defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
}

############
## Finder ##
############
function setupFinderDefaults(){
  # Disable warning when changing a file extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  # Disable warning when move file from icloud driver
  defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false
  # Show hidden files
  defaults write com.apple.finder AppleShowAllFiles TRUE
  # enable text selection in quick look windows
  defaults write com.apple.finder QLEnableTextSelection -bool TRUE
  # Use full POSIX path as window title
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
  # Disable the warning before emptying the Trash
  defaults write com.apple.finder WarnOnEmptyTrash -bool false
  # Disable .DS_Store in Finder
  defaults write com.apple.desktopservices DSDontWriteNetworkStores true
  # Disable the .DS_Store in USB
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
  # Set default view as Column View
  defaults write com.apple.finder FXPreferredViewStyle -string 'clmv'
  # Set the $HOME as default Finder
  defaults write com.apple.finder NewWindowTarget -string "PfLo" && defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
  # Show path
  defaults write com.apple.finder ShowPathbar -bool true
  # Show scrollbar
  defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
  # Allow quitting Finder via ⌘ + Q
  defaults write com.apple.finder QuitMenuItem -bool true
  # Set column view
  /usr/libexec/PlistBuddy -c 'Set :StandardViewOptions:ColumnViewOptions:FontSize 16' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :StandardViewOptions:ColumnViewOptions:ColumnWidth 280' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :StandardViewOptions:ColumnViewOptions:ArrangeBy modd' ~/Library/Preferences/com.apple.finder.plist
  # Set list view
  /usr/libexec/PlistBuddy -c 'Set :ComputerViewSettings:ListViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :ComputerViewSettings:ListViewSettings:sortColumn dateModified;' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:ListViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:ListViewSettings:sortColumn dateModified;' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :PackageViewSettings:ListViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :PackageViewSettings:ListViewSettings:sortColumn dateModified;' ~/Library/Preferences/com.apple.finder.plist
  # Set icon view
  /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:iconSize 72' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:iconSize 72' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:arrangeBy dateModified' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:arrangeBy dateModified' ~/Library/Preferences/com.apple.finder.plist

  killall Finder
  killall cfprefsd
}

##########
## Dock ##
##########
function setupDockDefaults(){
  # auto hide dock
  defaults write com.apple.dock autohide -bool true
  # remove the auto-hide dock delay
  defaults write com.apple.dock autohide-delay -float 0
  # minize mode
  defaults write com.apple.dock mineffect suck
  # highlight icon
  defaults write com.apple.dock mouse-over-hilite-stack -bool TRUE
  # remove none-opened icons
  defaults write com.apple.dock static-only -boolean true
  # hidden icons
  defaults write com.apple.dock showhidden -bool true
  # Set icon size
  defaults write com.apple.dock tilesize -int 50
  # Show indicator lights for open applications
  defaults write com.apple.dock show-process-indicators -bool true
  # Hot cornor
  # Top right screen corner →  Mission Control
  defaults write com.apple.dock wvous-tr-corner -int ${modifierMissionCtl}
  defaults write com.apple.dock wvous-tr-modifier -int ${modifierNone}
  # Bottom right screen corner →  application windows
  defaults write com.apple.dock wvous-br-corner -int ${modifierApplicationWindows}
  defaults write com.apple.dock wvous-br-modifier -int ${modifierNone}
  # Bottom left screen corner →  Desktop
  defaults write com.apple.dock wvous-bl-corner -int ${modifierDesktop}
  defaults write com.apple.dock wvous-bl-modifier -int ${modifierNone}

  killall Dock
}


###########
## Xcode ##
###########
function setupXcode(){
  sudo xcodebuild -license accept
  xcode-select --install
  # for pkgs
  for pkg in /Applications/Xcode.app/Contents/Resources/Packages/*.pkg; do
    sudo installer -pkg "$pkg" -target /;
  done
  # for componets
  /Applications/Xcode.app/Contents/MacOS/Xcode -installComponents
  # enable developer mode
  sudo sudo DevToolsSecurity -enable
}

##############
## Homebrew ##
##############
function installHomebrew(){
  sudo chown -R "$(whoami)":admin /usr/local
  ls -altrh /usr/
  ls -lO /usr/
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  git config --global http.proxy ''
  if brew --version; then
    brew --config
    brew tap caskroom/versions -v
    brew tap homebrew/dupes -v
    # brew tap homebrew/python -v
    brew update -v
    # setupBrewApps
  else
    echo 'brew install failed'
  fi
}

function setupBrewApps(){
  which -a brew
  whereis brew
  # git -C "$(brew --repo homebrew/core)" fetch --unshallow
  brew install coreutils
  brew install bash
  which -a bash
  /usr/local/bin/bash --version

  brew install wget tmux corkscrew tig ifstat binutils diffutils gawk gnutls gzip file-formula stow telnet iproute2mac ctags jshon colordiff tree vifm p7zip git mas htop watch jfrog-cli-go youtube-dl etcd mas figlet screenfetch glances bash-completion@2
  brew install shellcheck --HEAD
  brew install bats --HEAD
  brew install jq --devel --HEAD
  brew install gradle-completion --HEAD

  brew install gnu-sed --with-default-names
  brew install gnu-tar --with-default-names
  brew install gnu-which --with-default-names
  brew install grep --with-default-names
  brew install ed --with-default-names
  brew install findutils --with-default-names
  brew install wdiff --with-gettext
  brew install gnu-indent --with-default-names
  # brew install vim --override-system-vi

  brew cask install dash little-snitch iterm2-beta firefox google-chrome alfred vlc etcher imageoptim omnigraffle licecap xca manico snip jietu tickeys macdown
  # or $ brew cask install google-chrome-dev growl-fork android-sdk background-music

  brew tap macvim-dev/macvim
  # brew install --HEAD macvim-dev/macvim/macvim
  # OR
  brew install macvim --with-override-system-vim --HEAD


  brew install berkeley-db jack libmad libid3tag ffmpeg youtube-dl        # jackd -d coreaudio
  brew install moc --with-ncurses
  brew install mkdryden/homebrew-misc/namei

  brew cask outdated
  brew tap buo/cask-upgrade
  brew cu -a -f

  # setup mavim in /Applications
  VIMVER=$(/bin/ls -A1 /usr/local/Cellar/macvim/ | head -1)
  mkdir -p /Applications/gVim.app/Contents
  ln -sf /usr/local/Cellar/macvim/${VIMVER}/MacVim.app/Contents/* /Applications/gVim.app/Contents/
  mv /Applications/gVim.app/Contents/Info.plist{,.lnk}
  mv /Applications/gVim.app/Contents/PkgInfo{,.lnk}
  cp /Applications/gVim.app/Contents/Info.plist{.lnk,}
  cp /Applications/gVim.app/Contents/PkgInfo{.lnk,}

  # cat >> ~/.bash_profile << EOF
  # if [ -f $(brew --prefix)/etc/bash_completion ]; then"
    # . $(brew --prefix)/etc/bash_completion"
  # fi"
  # EOF

  chmod go-w /usr/local/opt

  if /usr/local/bin/bash --version; then
    sudo bash -c 'echo "/usr/local/bin/bash" >> /etc/shells'
    chsh -s /usr/local/bin/bash
    sudo chsh -s /usr/local/bin/bash
  fi
}

function npmInstall() {
  push .
  [ ! -d ~/mywork/tools/git/repo_tools ] && mkdir -p ~/mywork/tools/git/repo_tools/
  git clone https://github.com/tj/n ~/mywork/tools/git/repo_tools/n
  cd ~/mywork/tools/git/repo_tools/n
  make install
  which -a n
  popd
}

function npmSetup() {
  [ -f ~/.npmrc ] && mv ~/.npmrc{,.bak.${TIMESTAMP}}

  cat > $HOME/.npmrc << EOF
  registry=${ARTIFACTORYURL}/api/npm/npm-snapshot/g
  @appium=${ARTIFACTORYURL}/api/npm/npm-snapshotg
  @appium-chromedriver=${ARTIFACTORYURL}/api/npm/npm-snapshotg
  chromedriver_cdnurl=${ARTIFACTORYURL}/mirror-chromedriverg
  sass_binary_site=${ARTIFACTORYURL}/mirror-node-sassg
  phantomjs_cdnurl=${ARTIFACTORYURL}/mirror-phantomjsg
  nvm_nodejs_org_mirror=${ARTIFACTORYURL}/mirror-nodejsg
  nvm_iojs_org_mirror=${ARTIFACTORYURL}/mirror-iojs  g
  nvm_npm_mirror=${ARTIFACTORYURL}/mirror-npm        g
  # echo "progress=falseg
EOF

  sudo chown -R "$(whoami)":admin /usr/local

  n latest
  npm --version
  node --version

  npm i -g npm@latest --verbose
  npm i -g gnomon --verbose
}


function appManagement() {
  mas login marslo.jiao@gmail.com

  mas install 1256503523    # System Indicators
  mas install 836500024     # WeChat
  mas install 1233593954    # MailMaster
  mas install 467939042     # Growl
  mas install 497799835     # xCode
  mas install 736473980     # Paint
  mas install 520993579     # pwSafe
  mas install 944848654     # NeteaseMusic
  mas install 419330170     # moom
  mas install 405843582     # Alfred

  # setup iterm2
  curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash

  # Spotlight
  sudo mdutil -i on /
  sudo mdutil -E /
  sudo mdutil -E /Volumes/marslo/

  pip install rainbow
  pip install colout2

  sudo updatedb
}

function setupDefaults() {
  setupSystemDefaults
  setupDevDefaults
  setupAppstoreDefaults
  setupSafariDefaults
  setupFinderDefaults
  setupDockDefaults
}

function belloMarslo() {
  basicEnvSetup
  setupStartups
  setupDefaults
  setupXcode
  installHomebrew
  setupBrewApps
  npmInstall
  appManagement
}

setupBrewApps