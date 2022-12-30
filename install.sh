#!/bin/bash

# First uninstall any unnecessary packages.
apt update
apt -y install nano
apt -y install lsb-release
apt -y install ufw
systemctl stop apache2.service
systemctl stop sendmail.service
systemctl stop bind9.service
systemctl stop nscd.service
apt -y purge nscd bind9 sendmail apache2 apache2.2-common

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
