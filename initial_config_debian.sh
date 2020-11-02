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

# setup sudo
setup_sudo () {
    # check if user member of sudo group
    groups=$(groups $USER)
    if [[ $groups != *sudo* ]];then
        echo "First time setup for sudo"
        echo "     su -"
        echo "     apt-get install sudo"
        echo "     usermod -aG sudo <user>"
        echo "     re-login"
        exit
    else
        echo "Sudo Previously Setup"
    fi
}

# install packages
install_pkgs () {
  echo " "
  echo "Updating and upgrading packages"
  sudo apt-get update 
  sudo apt-get full-upgrade --yes --auto-remove
  sudo apt-get install $packages --yes
  echo " "
}

# sync dotfiles
dot_files () {
	git clone $dotfile_repo
    # set distro type in bash aliases
    echo " "
    echo "Setting distro in bash_aliases"
    sed -i '1cdistro=DEBIAN' Dotfiles/.bash_aliases
    # set user in bash aliases
    echo " "
    echo "Setting user in bash_aliases"
    sed -i "2cuser=$USER" Dotfiles/.bash_aliases
    # setup dotfiles
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    echo " "
    echo "Inlucde .config directory? [y/n]"
    while true
    do
        read response
        case $response in
            [yY]) rsync -arv --no-o --no-g --no-perms --exclude '.git' --exclude 'README.md' ./Dotfiles/ /home/$USER/; break ;;
            [nN]) rsync -arv --no-o --no-g --no-perms --exclude '.git' --exclude 'README.md' --exclude '.config' ./Dotfiles/ /home/$USER/; break ;;
            *) echo "Enter y or n" ;;
        esac
    done
    echo " "
    echo "Syncing dotfiles"
    source /home/$USER/.bashrc
    echo " "
    echo "Removing Dotfiles directory"
    rm -rf /home/$USER/Dotfiles
    echo " "
}

static_ip () {
  echo " "
  echo "Configuring static IP? [y/n]"
  while true
  do
          read response
          case $response in
                  [yY])
                    read -p "Enter the static IP address in the format xxx.xxx.xxx.xxx: " IP
                    read -p "Enter the static netmask in the format xxx.xxx.xxx.xxx: " NETMASK
                    read -p "Enter the static gateway in the format xxx.xxx.xxx.xxx: " GATEWAY

                    sudo sed -i 's/dhcp/static/g' /etc/network/interfaces
                    echo "    address $IP" | sudo tee -a /etc/network/interfaces
                    echo "    netmask $NETMASK" | sudo tee -a /etc/network/interfaces
                    echo "    gateway $GATEWAY" | sudo tee -a /etc/network/interfaces

                    echo "Restart required for changes to take effect"
                    break
                    ;;
                [nN]) break ;;
                *) echo "Please enter y or n" ;;
          esac
  done
}

host_name () {
  echo " "
  echo "Configuring Hostname? [y/n]"
  while true
  do
          read response
          case $response in
                  [yY])
                    read -p "Enter new hostname: " NEWNAME
                    sudo hostnamectl set-hostname $NEWNAME
                    # find appropriate line in hosts file
                    linenum=$(awk '/127.0.1.1/{ print NR; exit }' /etc/hosts)
                    # change hostname in hosts file
                    sudo sed -i "${linenum}c127.0.1.1       $NEWNAME" /etc/hosts
                    echo " "
                    echo "Hostname Changed"
                    echo "Restart required for changes to take effect"
                    break
                    ;;
                [nN]) break ;;
                *) echo "Please enter y or n" ;;
          esac
  done
}

setup_sudo
install_pkgs
dot_files
static_ip
host_name
