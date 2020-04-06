### BittyCLoud Readme

BittyCloud is forked from a project called TuxLite, a free collection of shell scripts for immidiate deployment of LEMP stacks (Linux, Nginx, MySQL and PHP 7.2) for Ubuntu and Debian.

BittyCloud only installs the very essentials to get your website up and running.

The following are going to be installed:

-   Nginx
-   Let's Encrypt
-   MySQL, MariaDB
-   PHP-FPM + commonly used PHP modules
-   Postfix mail server (securely configured to be outgoing only)

### Requirements

-   Supports Ubuntu 18.04, Debian 8.
-   A server with at least 512MB RAM. 1GB and above recommended.
-   Basic Linux knowledge. You will need know how to connect to your server remotely.
-   Basic text editor knowledge. For beginners, learning GNU nano is recommended.

If this is your first time with a Linux server, head over to [Digital Ocean](https://m.do.co/c/1eb2baff1acd) Community section and I suggest spending some time reading through tutorials.

### Quick Install (Git)

    # Install git and clone BittyCloud
    git clone https://github.com/giobautista/BittyCloud.git
    cd BittyCloud

    # Make all scripts executable.
    chmod 700 *.sh
    chmod 700 options.conf

    # Edit options to enter server IP, MariaDB/MySQL password etc.
    nano options.conf

    # Install LEMP stack.
    ./install.sh

    # Add a new Linux user and add domains to the user.
    adduser johndoe
    ./domain.sh add johndoe yourdomain.com
    ./domain.sh add johndoe subdomain.yourdomain.com
    
    # Add SSL certificates using Let's Encrypt
    ./domain.sh ssl user Domain.ltd

    # Install Adminer or phpMyAdmin
    ./setup.sh dbgui

    # Enable/disable public viewing of Adminer/phpMyAdmin
    ./domain.sh dbgui on
    ./domain.sh dbgui off

## DO NOT FORGET TO ADD A USER WITH SUDO CAPABILITY!

#### TO DO
- Database management
    + db (add, remove)
    + user (add, remove)
