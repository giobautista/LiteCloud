#!/bin/bash

# Check root
if [ "$(id -u)" = "0" ]; then
    clear
else
    clear
    echo -e "\033[35;1mYou must have root access to run this script\033[0m"
    exit 1
fi

echo ""
echo "Preparing server"
sleep 5
sudo apt update
sudo apt -y upgrade
sudo apt -y install nano expect lsb-release ufw curl wget vim rpl sed zip unzip openssl dirmngr dos2unix
sudo systemctl stop apache2.service
sudo systemctl stop sendmail.service
sudo systemctl stop bind9.service
sudo systemctl stop nscd.service
sudo apt -y purge nscd bind9 sendmail apache2 apache2.2-common

echo ""
echo "Installing updates & configuring SSHD / hostname."
sleep 5
./setup.sh basic

echo ""
echo "Installing LEMP stack."
sleep 5
./setup.sh install

echo ""
echo "Installing phpmyadmin/adminer."
sleep 5
./setup.sh dbgui

echo ""
echo "Installing Let's Encrypt Certbot."
sleep 5
./setup.sh letsencrypt

echo ""
echo "Optimizing AWStats, PHP, logrotate & webserver config."
sleep 5
./setup.sh optimize

## Uncomment to secure /tmp folder
#echo ""
#echo "Securing /tmp directory."
## Use tmpdd here if your server has under 256MB memory. Tmpdd will consume a 1GB disk space for /tmp
#./setup.sh tmpfs

echo ""
echo -e "\033[36;1m Installation complete! \033[0m"
echo -e "\033[35;1m Root login disabled. \033[0m"
echo -e "\033[35;1m Please add a normal user now using the \"adduser\" command. \033[0m"
