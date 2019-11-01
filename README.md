### CloudLite Readme

CloudLite is a free collection of shell scripts for rapid deployment of LEMP stacks (Linux, Nginx, MySQL and PHP 7.2) for Debian and Ubuntu.

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

### DO NOT FORGET TO ADD A REGULAR USER WITH SUDOER CAPABILITY!

### Last step is to add user to database

    # Create a database
    mysql> CREATE DATABASE `mydb`;

    # Create a user
    mysql> CREATE USER 'myuser' IDENTIFIED BY 'mypassword';

    # Grant permissions to access and use the MySQL server
    # Only allow access from localhost (secure and common configuration to use for a web application):
    mysql> GRANT USAGE ON *.* TO 'myuser'@localhost IDENTIFIED BY 'mypassword';

    # To allow access to MySQL server from any other computer on the network:
    mysql> GRANT USAGE ON *.* TO 'myuser'@'%' IDENTIFIED BY 'mypassword';

    # Grant all privileges to a user on a specific database
    mysql> GRANT ALL privileges ON `mydb`.* TO 'myuser'@localhost;

    # CREATING ANOTHER SUPER USER (not safe! has ALL privileges across ALL databases on the server)
    mysql> GRANT ALL PRIVILEGES ON *.* TO 'myuser'@'%';

    # Save the changes
    mysql> FLUSH PRIVILEGES;

### Requirements

-   Supports Debian 8, Ubuntu 18.04.
-   A server with at least 256MB RAM. 512MB and above recommended.
-   Basic Linux knowledge. You will need know how to connect to your
    server remotely.
-   Basic text editor knowledge. For beginners, learning GNU nano is
    recommended.

If this is your first time with a Linux server, I suggest spending a day reading the "getting started" tutorials in Linode Library.