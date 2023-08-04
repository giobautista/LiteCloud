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
clear
echo "Preparing server"
sleep 2

apt update
apt -y upgrade
apt -y install git nano expect lsb-release ufw curl wget vim rpl sed zip unzip openssl dirmngr dos2unix
systemctl stop apache2.service
systemctl stop sendmail.service
systemctl stop bind9.service
systemctl stop nscd.service
apt -y purge nscd bind9 sendmail apache2 apache2.2-common

echo ""
clear
echo "Installing updates & configuring SSHD / hostname."
sleep 2
./setup.sh basic

echo ""
clear
echo "Installing LEMP stack."
sleep 2
./setup.sh install

echo ""
clear
echo "Installing phpmyadmin/adminer."
sleep 2
./setup.sh dbgui

echo ""
clear
echo "Installing Let's Encrypt Certbot."
sleep 2
./setup.sh letsencrypt

echo ""
clear
echo "Optimizing AWStats, PHP, logrotate & webserver config."
sleep 2
./setup.sh optimize

## Uncomment to secure /tmp folder
#echo ""
#echo "Securing /tmp directory."
## Use tmpdd here if your server has under 256MB memory. Tmpdd will consume a 1GB disk space for /tmp
#./setup.sh tmpfs

echo ""
echo -e "\033[36;1m Installation complete! \033[0m"
echo -e "\033[35;1m Root login disabled. \033[0m"
echo -e "\033[35;1m Remember to use SUDO credentials for login or you will be locked out from your box! \033[0m"
