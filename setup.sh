#!/bin/bash

source ./options.conf

#### Functions Begin ####

function server_init {
  # Detect distribution. Debian or Ubuntu
  DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

  if [ $DISTRO != "ubuntu" ]; then
      echo -e "\033[35;1mSorry, the installation only support Ubuntu\033[0m"
      exit 1
  fi

  apt update
  apt -y install git nano expect lsb-release ufw curl wget vim rpl sed zip unzip openssl dirmngr dos2unix
  systemctl stop apache2.service
  systemctl stop sendmail.service
  systemctl stop bind9.service
  systemctl stop nscd.service
  apt -y purge nscd bind9 sendmail apache2 apache2.2-common

} #End function server_init

function basic_server_setup {
  # Get server's IP
  SERVER_IP=$(curl -s https://checkip.amazonaws.com)

  # Set timezone
  echo -e "\033[35;1m Setting Timezone... \033[0m"
  timedatectl set-timezone $TIME_ZONE
  sleep 2

  # Reconfigure sshd - change port and disable root login
  echo -e "\033[35;1m Configuring SSH... \033[0m"
  sed -i 's/^Port [0-9]*/Port '${SSHD_PORT}'/' /etc/ssh/sshd_config
	if  [ $ROOT_LOGIN = "no" ]; then
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
	fi;
  # Enable Password Authentication
  sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  systemctl reload ssh.service

  # Set hostname and FQDN
  sed -i 's/'${SERVER_IP}'.*/'${SERVER_IP}' '${HOSTNAME_FQDN}' '${HOSTNAME}'/' /etc/hosts
  echo "$HOSTNAME_FQDN" > /etc/hostname

  # Basic hardening of sysctl.conf
  sed -i 's/^#net.ipv4.conf.all.accept_source_route = 0/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
  sed -i 's/^net.ipv4.conf.all.accept_source_route = 1/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
  sed -i 's/^#net.ipv6.conf.all.accept_source_route = 0/net.ipv6.conf.all.accept_source_route = 0/' /etc/sysctl.conf
  sed -i 's/^net.ipv6.conf.all.accept_source_route = 1/net.ipv6.conf.all.accept_source_route = 0/' /etc/sysctl.conf

  if  [ $ROOT_LOGIN = "no" ]; then
    useradd -m -s /bin/bash $SUDO_USER
    echo "$SUDO_USER:$SUDO_PASS"|chpasswd
    usermod -aG sudo $SUDO_USER

    echo -e "\033[35;1m Root login disabled, SSH port set to $SSHD_PORT. \033[0m"
    echo -e "\033[35;1m Remember to use credentials for login or you will be locked out from your box! \033[0m"

  else
      echo -e "\033[35;1m Root login active, SSH port set to $SSHD_PORT. \033[0m"
  fi

} # End function basic_server_setup

function install_webserver {
  # Install NGINX
  apt -y install nginx-core
  systemctl start nginx.service

  # Add a catch-all default vhost
  cat ./config/nginx_default_vhost.conf > /etc/nginx/sites-available/default

  # Change default vhost root directory to /usr/share/nginx/html;
  sed -i 's/\(root \/usr\/share\/nginx\/\).*/\1html;/' /etc/nginx/sites-available/default

  # Create common SSL config file
  cat > /etc/nginx/ssl.conf <<EOF
ssl on;
ssl_certificate /etc/ssl/localcerts/webserver.pem;
ssl_certificate_key /etc/ssl/localcerts/webserver.key;

ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
EOF

  systemctl enable nginx.service

} # End function install_webserver

function configure_firewall {
  # Configure firewall
  apt-get -y install fail2ban
  JAIL=/etc/fail2ban/jail.local
  unlink JAIL
  touch $JAIL
  cat > "$JAIL" <<EOF
[DEFAULT]
bantime = 3600
banaction = iptables-multiport
[sshd]
enabled = true
logpath  = /var/log/auth.log
EOF
  systemctl restart fail2ban
  ufw --force enable
  ufw allow ssh
  ufw allow http
  ufw allow https
  ufw allow "Nginx Full"
  utf reload

} # End funtion configure_firewall

function install_php {
  # Add PHP repo
  apt install -y ca-certificates apt-transport-https software-properties-common
  add-apt-repository -y ppa:ondrej/php
  apt update

  # Install PHP packages and extensions specified in options.conf
  apt -y install $PHP_BASE
  apt -y install $PHP_EXTRAS

  # Enable PHP-FPM
  systemctl enable php8.1-fpm

} # End function install_php

function install_extras {
  if [ $AWSTATS_ENABLE = 'yes' ]; then
    apt -y install awstats
  fi

  # Install any other packages specified in options.conf
  apt -y install $MISC_PACKAGES

} # End function install_extras

function install_mysql {
  # Check if user wants mariadb
  if [ $DBSERVER = 1 ]; then
    apt -y install mariadb-server mariadb-client

    echo -e "\033[35;1m Securing MariaDB... \033[0m"
    sleep 2

    SECURE_MARIADB=$(expect -c "
        set timeout 10
        spawn mysql_secure_installation
        expect \"Enter current password for root (enter for none):\"
        send \"$MYSQL_ROOT_PASS\r\"
        expect \"Change the root password?\"
        send \"n\r\"
        expect \"Remove anonymous users?\"
        send \"Y\r\"
        expect \"Disallow root login remotely?\"
        send \"Y\r\"
        expect \"Remove test database and access to it?\"
        send \"Y\r\"
        expect \"Reload privilege tables now?\"
        send \"Y\r\"
        expect eof
    ")
    echo "$SECURE_MARIADB"

  else
    apt -y install mysql-server mysql-client

    echo -e "\033[35;1m Securing MySQL... \033[0m"
    sleep 2

    SECURE_MYSQL=$(expect -c "
        set timeout 10
        spawn mysql_secure_installation
        expect \"Press y|Y for Yes, any other key for No:\"
        send \"n\r\"
        expect \"New password:\"
        send \"$MYSQL_ROOT_PASS\r\"
        expect \"Re-enter new password:\"
        send \"$MYSQL_ROOT_PASS\r\"
        expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No)\"
        send \"y\r\"
        expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No)\"
        send \"n\r\"
        expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No)\"
        send \"y\r\"
        expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) \"
        send \"y\r\"
        expect eof
    ")
    echo "$SECURE_MYSQL"

    /usr/bin/mysql -u root -p$MYSQL_ROOT_PASS <<EOF
use mysql;
CREATE USER '$MYSQL_ROOT_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_ROOT_USER'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

  fi
} # End function install_mysql

function optimize_stack {
  # If using Nginx, copy over nginx.conf
  cat ./config/nginx.conf > /etc/nginx/nginx.conf

  # Change logrotate for nginx log files to keep 10 days worth of logs
  nginx_file=`find /etc/logrotate.d/ -maxdepth 1 -name "nginx*"`
  sed -i 's/\trotate .*/\trotate 10/' $nginx_file

  if [ $AWSTATS_ENABLE = 'yes' ]; then
    # Configure AWStats
    temp=`grep -i sitedomain /etc/awstats/awstats.conf.local | wc -l`
    if [ $temp -lt 1 ]; then
      echo SiteDomain="$HOSTNAME_FQDN" >> /etc/awstats/awstats.conf.local
    fi
    # Disable Awstats from executing every 10 minutes. Put a hash in front of any line.
    sed -i 's/^[^#]/#&/' /etc/cron.d/awstats
  fi

  systemctl stop php8.1-fpm.service

  php_fpm_conf="/etc/php/*/fpm/pool.d/www.conf"
  # Limit FPM processes
  sed -i 's/^pm.max_children.*/pm.max_children = '${FPM_MAX_CHILDREN}'/' $php_fpm_conf
  sed -i 's/^pm.start_servers.*/pm.start_servers = '${FPM_START_SERVERS}'/' $php_fpm_conf
  sed -i 's/^pm.min_spare_servers.*/pm.min_spare_servers = '${FPM_MIN_SPARE_SERVERS}'/' $php_fpm_conf
  sed -i 's/^pm.max_spare_servers.*/pm.max_spare_servers = '${FPM_MAX_SPARE_SERVERS}'/' $php_fpm_conf
  sed -i 's/\;pm.max_requests.*/pm.max_requests = '${FPM_MAX_REQUESTS}'/' $php_fpm_conf
  # Change to socket connection for better performance
  sed -i 's/^listen =.*/listen = \/var\/run\/php8.1-fpm.sock/' $php_fpm_conf

  php_ini_dir="/etc/php/*/fpm/php.ini"
  # Tweak php.ini based on input in options.conf
  sed -i 's/^max_execution_time.*/max_execution_time = '${PHP_MAX_EXECUTION_TIME}'/' $php_ini_dir
  sed -i 's/^memory_limit.*/memory_limit = '${PHP_MEMORY_LIMIT}'/' $php_ini_dir
  sed -i 's/^max_input_time.*/max_input_time = '${PHP_MAX_INPUT_TIME}'/' $php_ini_dir
  sed -i 's/^post_max_size.*/post_max_size = '${PHP_POST_MAX_SIZE}'/' $php_ini_dir
  sed -i 's/^upload_max_filesize.*/upload_max_filesize = '${PHP_UPLOAD_MAX_FILESIZE}'/' $php_ini_dir
  sed -i 's/^expose_php.*/expose_php = Off/' $php_ini_dir
  sed -i 's/^cgi.fix_pathinfo.*/cgi.fix_pathinfo = 0/' $php_ini_dir
  sed -i 's/^disable_functions.*/disable_functions = exec,system,passthru,shell_exec,escapeshellarg,escapeshellcmd,proc_close,proc_open,dl,popen,show_source/' $php_ini_dir

  restart_webserver
  sleep 2
  systemctl start php8.1-fpm.service
  sleep 2
  systemctl restart php8.1-fpm.service
  echo -e "\033[35;1m Optimization complete! \033[0m"

} # End function optimize

function install_postfix {
  # Install postfix
  echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
  echo "postfix postfix/mailname string $HOSTNAME_FQDN" | debconf-set-selections
  echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections
  apt -y install postfix

  # Allow mail delivery from localhost only
  /usr/sbin/postconf -e "inet_interfaces = loopback-only"

  sleep 1
  postfix stop
  sleep 1
  postfix start
  sleep 1
  systemctl restart postfix

} # End function install_postfix

function install_dbgui {
  # If user selected phpMyAdmin in options.conf
  if [ $DB_GUI = 1  ]; then
    mkdir /tmp/phpmyadmin
    PMA_VER="`wget -q -O - https://www.phpmyadmin.net/downloads/|grep -m 1 '<h2>phpMyAdmin'|sed -r 's/^[^3-9]*([0-9.]*).*/\1/'`"
    wget -O - "https://files.phpmyadmin.net/phpMyAdmin/${PMA_VER}/phpMyAdmin-${PMA_VER}-all-languages.tar.gz" | tar zxf - -C /tmp/phpmyadmin

    # Check exit status to see if download is successful
    if [ $? = 0  ]; then
      mkdir /usr/local/share/phpmyadmin
      rm -rf /usr/local/share/phpmyadmin/*
      cp -Rpf /tmp/phpmyadmin/*/* /usr/local/share/phpmyadmin
      cp /usr/local/share/phpmyadmin/{config.sample.inc.php,config.inc.php}
      rm -rf /tmp/phpmyadmin

      # Generate random blowfish string
      LENGTH="20"
      MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
      while [ "${n:=1}" -le "$LENGTH" ]; do
        BLOWFISH="$BLOWFISH${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
      done

      # Configure phpmyadmin blowfish variable
      sed -i "s/blowfish_secret'] = ''/blowfish_secret'] = \'$BLOWFISH\'/"  /usr/local/share/phpmyadmin/config.inc.php
      echo -e "\033[35;1mphpMyAdmin installed/upgraded.\033[0m"
    else
      echo -e "\033[35;1mInstall/upgrade failed. Perhaps phpMyAdmin download link is temporarily down. Update link in options.conf and try again.\033[0m"
    fi

  else # User selected Adminer

    mkdir -p /usr/local/share/adminer
    cd /usr/local/share/adminer
    rm -rf /usr/local/share/adminer/*
    wget http://www.adminer.org/latest.php
    if [ $? = 0  ]; then
      mv latest.php index.php
      echo -e "\033[35;1m Adminer installed. \033[0m"
    else
      echo -e "\033[35;1mInstall/upgrade failed. Perhaps http://adminer.org is down. Try again later.\033[0m"
    fi
    cd - &> /dev/null
  fi # End if DB_GUI

} # End function install_dbgui

function check_tmp_secured {

  temp1=`grep -w "/var/tempFS /tmp ext3 loop,nosuid,noexec,rw 0 0" /etc/fstab | wc -l`
  temp2=`grep -w "tmpfs /tmp tmpfs rw,noexec,nosuid 0 0" /etc/fstab | wc -l`

  if [ $temp1  -gt 0 ] || [ $temp2 -gt 0 ]; then
    return 1
  else
    return 0
  fi

} # End function check_tmp_secured

function secure_tmp_tmpfs {

  cp /etc/fstab /etc/fstab.bak
  # Backup /tmp
  cp -Rpf /tmp /tmpbackup

  rm -rf /tmp
  mkdir /tmp

  mount -t tmpfs -o rw,noexec,nosuid tmpfs /tmp
  chmod 1777 /tmp
  echo "tmpfs /tmp tmpfs rw,noexec,nosuid 0 0" >> /etc/fstab

  # Restore /tmp
  cp -Rpf /tmpbackup/* /tmp/ >/dev/null 2>&1

  #Remove old tmp dir
  rm -rf /tmpbackup

  # Backup /var/tmp and link it to /tmp
  mv /var/tmp /var/tmpbackup
  ln -s /tmp /var/tmp

  # Copy the old data back
  cp -Rpf /var/tmpold/* /tmp/ >/dev/null 2>&1
  # Remove old tmp dir
  rm -rf /var/tmpbackup

  echo -e "\033[35;1m /tmp and /var/tmp secured using tmpfs. \033[0m"

} # End function secure_tmp_tmpfs

function secure_tmp_dd {

  cp /etc/fstab /etc/fstab.bak

  # Create 1GB space for /tmp, change count if you want smaller/larger size
  dd if=/dev/zero of=/var/tempFS bs=1024 count=$TMP_SIZE
  # Make space as a ext3 filesystem
  /sbin/mkfs.ext3 /var/tempFS

  # Backup /tmp
  cp -Rpf /tmp /tmpbackup

  # Secure /tmp
  mount -o loop,noexec,nosuid,rw /var/tempFS /tmp
  chmod 1777 /tmp
  echo "/var/tempFS /tmp ext3 loop,nosuid,noexec,rw 0 0" >> /etc/fstab

  # Restore /tmp
  cp -Rpf /tmpbackup/* /tmp/ >/dev/null 2>&1

  # Remove old tmp dir
  rm -rf /tmpbackup

  # Backup /var/tmp and link it to /tmp
  mv /var/tmp /var/tmpbackup
  ln -s /tmp /var/tmp

  # Copy the old data back
  cp -Rpf /var/tmpold/* /tmp/ >/dev/null 2>&1
  # Remove old tmp dir
  rm -rf /var/tmpbackup

  echo -e "\033[35;1m /tmp and /var/tmp secured using file created using dd. \033[0m"

} # End function secure_tmp_tmpdd

function install_letsencrypt {
  # Install Let's Encrypt
  apt update
  apt install -y certbot python3-certbot-nginx
  ufw allow 'Nginx Full'
  ufw delete allow 'Nginx HTTP'

} # End function install_letsencrypt

function restart_webserver {

  systemctl restart nginx.service

} # End function restart_webserver

if [ ! -n "$1" ]; then
  echo ""
  echo -e  "\033[35;1mPlease run ./install.sh to initiate the process\033[0m"
  echo ""
fi

# Show Menu
if [ ! -n "$1" ]; then
  echo ""
  echo -e  "\033[35;1mNOTICE: Edit options.conf before using\033[0m"
  echo -e  "\033[35;1mA standard setup would be: basic + install + optimize\033[0m"
  echo ""
  echo -e  "\033[35;1mSelect from the options below to use this script:- \033[0m"

  echo -n  "$0"
  echo -ne "\033[36m basic\033[0m"
  echo     " - Disable root SSH logins, change SSH port."

  echo -n "$0"
  echo -ne "\033[36m install\033[0m"
  echo     " - Installs LNMP stack. Also installs Postfix MTA."

  echo -n "$0"
  echo -ne "\033[36m optimize\033[0m"
  echo     " - Optimizes webserver.conf, php.ini, AWStats & logrotate. Also generates self signed SSL certs."

  echo -n "$0"
  echo -ne "\033[36m letsencrypt\033[0m"
  echo     " - Installing Let's Encrypt"

  echo -n "$0"
  echo -ne "\033[36m dbgui\033[0m"
  echo     " - Installs or updates Adminer/phpMyAdmin."

  echo -n "$0"
  echo -ne "\033[36m tmpfs\033[0m"
  echo     " - Secures /tmp and /var/tmp using tmpfs. Not recommended for servers with less than 512MB dedicated RAM."

  echo -n "$0"
  echo -ne "\033[36m tmpdd\033[0m"
  echo     " - Secures /tmp and /var/tmp using a file created on disk. Tmp size is defined in options.conf."

  echo ""
  exit
fi # End Show Menu

case $1 in
basic)
  server_init
  basic_server_setup
  ;;
install)
  install_webserver
  configure_firewall
  install_mysql
  install_php
  install_extras
  install_postfix
  restart_webserver
  systemctl restart php8.1-fpm.service
  echo -e "\033[35;1m Webserver + PHP-FPM + MySQL install complete! \033[0m"
  ;;
optimize)
  optimize_stack
  ;;
letsencrypt)
  install_letsencrypt
  ;;
dbgui)
  install_dbgui
  ;;
tmpdd)
  check_tmp_secured
  if [ $? = 0  ]; then
    secure_tmp_dd
  else
    echo -e "\033[35;1mFunction canceled. /tmp already secured. \033[0m"
  fi
  ;;
tmpfs)
  check_tmp_secured
  if [ $? = 0  ]; then
    secure_tmp_tmpfs
  else
    echo -e "\033[35;1mFunction canceled. /tmp already secured. \033[0m"
  fi
  ;;
esac
