#!/bin/bash

#
#
# Forked from github.com/txoof/piconfig
#
#

# list of packages that should be installed immediately
packages="git vim python3 python3-pip rsync"

# dotfiles are stored here
dotfile_repo="https://github.com/jcurtis4207/Dotfiles.git"

# change the default password
ch_password () {
	echo " "
	echo "Setting password for user $USER"
	passwd
	echo " "
}

locale () {
  sudo dpkg-reconfigure tzdata
}

# install packages
install_pkgs () {
  echo " "
  echo "Updating and upgrading packages"
  sudo apt-get update 
  sudo apt-get full-upgrade --yes --auto-remove 
  sudo apt-get install "$packages" --yes
  echo " "
}

# sync dotfiles
dot_files () {
	git clone $dotfile_repo
    # set distro type in bash aliases
    echo "Setting distro in bash_aliases"
    sed -i '1cdistro=DEBIAN' Dotfiles/.bash_aliases
    # set user in bash aliases
    echo "Setting user in bash_aliases"
    sed -i "2cuser=$USER" Dotfiles/.bash_aliases
    # setup dotfiles
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    echo "Inlucde .config directory? [y/n]"
    while true
    do
        read -r response
        case $response in
            [yY]) rsync -arv --no-o --no-g --no-perms --exclude '.git' --exclude 'README.md' ./Dotfiles/ /home/"$USER"/; break ;;
            [nN]) rsync -arv --no-o --no-g --no-perms --exclude '.git' --exclude 'README.md' --exclude '.config' ./Dotfiles/ /home/"$USER"/; break ;;
            *) echo "Enter y or n" ;;
        esac
    done
    echo "Syncing dotfiles"
    source /home/"$USER"/.bashrc
    echo "Removing Dotfiles directory"
    rm -rf /home/"$USER"/Dotfiles
    echo " "
}

# function for checking input
# usage: contains array variable
contains () {
  typeset _x;
  typeset -n _A="$1"
  for _x in "${_A[@]}"; do
    [ "$_x" = "$2" ] && return 0
  done
  return 1
}

static_ip () {
  interfaces=()
  echo "Configuring static IP"
  echo "Choose an interface to configure -- enter 'None' to skip"
  # list all the available interfaces
  for iface in $(ifconfig | cut -d ' ' -f1 | tr ':' '\n'|awk NF)
  do
    printf "%s\n" "$iface"
    interfaces+=("$iface")
  done
  # add 'None' as an option in the list
  iface="None"
  printf "%s\n" "$iface"
  interfaces+=("$iface")

  # loop until user enters a valid interface from the list
  echo "${interfaces[@]}"
  echo " "
  while read -p "Interface: " -r user_iface;
      ! contains interfaces "$user_iface"; do
    echo "$user_iface is not a valid interface!"
  done
  case $user_iface in
    None)
      echo "skipping static IP configuration"; return 0;;
  esac

  read -rp "Enter the static IP address in the format xxx.xxx.xxx.xxx/yy: " IP
  read -rp "Enter static router address in the format xxx.xxx.xxx.xxx: " ROUTER
  read -rp "Enter the static DNS in the format xxx.xxx.xxx.xxx: " DNS

  tmpFile=/tmp/static.ip
  echo "interface $user_iface" > $tmpFile
  echo "static ip_address=$IP" >> $tmpFile
  echo "static routers=$ROUTER" >> $tmpFile
  echo "static domain_name_servers=$DNS" >> $tmpFile

  echo "current /etc/dhcpcd.conf"
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  cat /etc/dhcpcd.conf

  echo "appending dhcpcd.conf"
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  cat $tmpFile

  echo " "
  read -rp "Continue with replacement? [Y/n]: " REPLACE
  case $REPLACE in
    [nN]*) echo "skipping..."; return 0;;
    [yY]*) echo "replacing here"; cat $tmpFile | sudo tee -a /etc/dhcpcd.conf;;
        *) echo "skipping..."; return 0;;
  esac
  echo "Restart required for changes to take effect"
}

# set the hostname
host_name () {
	echo " "
    CURRENT_HOSTNAME=$(cat /etc/hostname | tr -d " \t\n\r")
	echo "Current hostname: $CURRENT_HOSTNAME"
	echo "Would you like to change this hostname?"
	read -rp "Please enter a new hostname or press enter to skip: " NEW_HOSTNAME
	if [[ $NEW_HOSTNAME ]]; then
		echo "$NEW_HOSTNAME" | sudo tee /etc/hostname
		sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
		echo "please reboot for hostname changes to take effect"
    else
        echo "hostname unchanged"
	    echo " "
        return 0
	fi
}

ch_password
locale
install_pkgs
dot_files
static_ip
host_name
