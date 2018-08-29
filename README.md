### CloudLite Readme

CloudLite is a free collection of shell scripts for rapid deployment of LNMP stacks (Linux, Nginx, MySQL and PHP 7.0) for Debian and Ubuntu.

The following are installed:-

-   Nginx
-   MySQL, MariaDB
-   PHP-FPM + commonly used PHP modules
-   Postfix mail server (securely configured to be outgoing only)
-   Varnish cache (optional)

For more detailed explanation on the installation, usage and script features,
kindly refer to these links:-

### Quick Install (Git)

    # Install git and clone CloudLite
    apt-get -y install git
    git clone https://github.com/giobautista/CloudLite.git
    cd CloudLite

    # Edit options to enter server IP, MySQL password etc.
    nano options.conf

    # Make all scripts executable.
    chmod 700 *.sh
    chmod 700 options.conf

    # Install LAMP or LNMP stack.
    ./install.sh

    # Add a new Linux user and add domains to the user.
    adduser johndoe
    ./domain.sh add johndoe yourdomain.com
    ./domain.sh add johndoe subdomain.yourdomain.com

    # Install Adminer or phpMyAdmin
    ./setup.sh dbgui

    # Enable/disable public viewing of Adminer/phpMyAdmin
    ./domain.sh dbgui on
    ./domain.sh dbgui off

### Requirements

-   Supports Debian 8, Ubuntu 16.04.
-   A server with at least 256MB RAM. 512MB and above recommended.
-   Basic Linux knowledge. You will need know how to connect to your
    server remotely.
-   Basic text editor knowledge. For beginners, learning GNU nano is
    recommended.

If this is your first time with a Linux server, I suggest spending a day reading the "getting started" tutorials in Linode Library.