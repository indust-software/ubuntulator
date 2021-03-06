# !/bin/bash
#
# Main installation script. Should be run with sudo privilages and most likely run from ./install.sh script.
# User should not execute this script directly.

# Default variables
# ------------------

source ./helpers/prompter;

# check if user is root
if [ $USER != 'root' ]; then
  error "Please run install.sh";
  exit 1;
fi

# Global constants
PROMPT_TITLE="Ubuntu Development Setup";
EX_USER="$(sh -c 'echo $SUDO_USER')"
# get system version info variables
# DISTRIB_ID
# DISTRIB_RELEASE
# DISTRIB_CODENAME
# DISTRIB_DESCRIPTION
source /etc/lsb-release

# Detect the architecture
if [ "$(uname -m)" = "x86_64" ]; then
  ARCHITECTURE="x64"
else
  ARCHITECTURE="x32"
fi

# Default selected environments
ENV_NGINX=ON;
ENV_NODE=ON;
ENV_GO=ON;

# Default paths
NGINX_WWW_PATH=$HOME"/www";
NGINX_SSL_OPTIONS='/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com'
SCRIPT_DIR="$(pwd)"
SSL_PATH=$HOME/.ssl

source ./helpers/postinstall;
source ./helpers/debinstall;

# Create welcome screen
whiptail --title "$PROMPT_TITLE" \
--msgbox "This script will configure your development environment. It will \
install most common applications and configure system to be ready for \
developers.\n\n Choose Ok to continue." 13 60

# Collect environments to be installed
ENVIRONMENTS=$(whiptail --title "$PROMPT_TITLE" --checklist \
"Choose preferred environments that will be instaled on your machine:" 13 60 4 \
"nginx" "Nginx + PHP5 + MySQL + PhpMyAdmin    " $ENV_NGINX \
"node" "Node.js with Homebrew" $ENV_NODE \
"golang" "Go with GVM" $ENV_GO 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 0 ]; then
    ENVIRONMENTS=($ENVIRONMENTS);
else
    ENVIRONMENTS=''
fi

summaryBlock 'Installation complete!'
summaryMessage 'Thank you for using Ubuntulator. Here is installation summary.'

# For each selected environment collect all required data
for env in "${ENVIRONMENTS[@]}"; do
  # Run nginx prompt
  if [ "$env" == '"nginx"' ]
    then source ./prompts/nginx-prompt;
  fi

  # Run node prompt
  if [ "$env" == '"node"' ]
    then source ./prompts/node-prompt;
  fi

  # Run go prompt
  if [ "$env" == '"golang"' ]
    then source ./prompts/go-prompt;
  fi
done

source ./prompts/git-prompt;
source ./prompts/software-prompt;

if (whiptail --title "$PROMPT_TITLE" --yes-button "Yes, install" \
    --no-button "No, maybe later" \
    --yesno "All information is collected. Do you want to proceed?" 10 60) then
    block 'Prepare system for installation';
else
    exit 1;
fi

#Preparing for installation
info 'Updating system repositories...'
apt-get -qq update

# Perform common instalation
source ./installers/common-install;

# Install software
if [ "$USE_NGINX" == 'true' ]
  then source ./installers/nginx-install;
fi

if [ "$USE_NODE" == 'true' ]
  then source ./installers/node-install;
fi

if [ "$USE_GOLANG" == 'true' ]
  then source ./installers/go-install;
fi

if [ "$GIT_SSH_SERVICES" != "" ]; then
  source ./installers/git-ssh-installer;
fi

if [ "$SOFTWARE" != "" ]; then
  source ./installers/software-install;
fi
