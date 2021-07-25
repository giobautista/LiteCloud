### LiteCloud Readme

LiteCloud is based on a project called TuxLite, a free collection of shell scripts for immidiate deployment of LEMP stacks (Linux, Nginx, MySQL and PHP 7.4) for Ubuntu 20.04 (TLS) x64.

### The following are going to be installed:

-   Nginx
-   MariaDB, MySQL
-   PHP-FPM + commonly used PHP modules
-   Let's Encrypt SSL (in progress)
-   Postfix mail server (securely configured to be outgoing only)

### Requirements

-   Supports Ubuntu 18.04, Debian 8.
-   A server with at least 512MB RAM. 1GB and above recommended.
-   Basic Linux knowledge. You will need know how to connect to your server remotely.
-   Basic text editor knowledge. For beginners, learning GNU nano is recommended.

If this is your first time with a Linux server, head over to [Digital Ocean](https://m.do.co/c/1eb2baff1acd) Community section and I suggest spending some time reading through tutorials.

### Quick Install (Git)

    # Install git and clone LiteCloud
    git clone https://github.com/giobautista/LiteCloud.git ; cd LiteCloud ; chmod 700 *.sh ; chmod 700 options.conf

    # Edit options to enter server IP, MariaDB/MySQL password etc.
    nano options.conf

    # Install LEMP stack.
    ./install.sh

### Add a new Linux user then add to sudoer (since root is now disabled).

    # To add user
    adduser johnsmith

    # To add user to sudoer
    usermod -aG sudo johnsmith

### Add domain to the user

    # Add domains to the user
    ./domain.sh add johnsmith yourdomain.com
    ./domain.sh add johnsmith subdomain.yourdomain.com

    # Add SSL certificates using Let's Encrypt
    ./domain.sh ssl johnsmith yourdomain.com
    ./domain.sh ssl johnsmith subdomain.yourdomain.com

    # Install Adminer or phpMyAdmin
    ./setup.sh dbgui

    # Enable/disable public viewing of Adminer/phpMyAdmin
    ./domain.sh dbgui on
    ./domain.sh dbgui off

### Database and database user management

    # Create and drop database
    ./database.sh new db - Create new database
    ./database.sh rem db - Destroy a database (cannot be undone)

    # Create and remove user
    ./database.sh new user - Create new user
    ./database.sh new super_user - Create new SUPER user
    ./database.sh rem user - Remove a user (cannot be undone)

### So, why Nginx only?

We want to run a very efficient webserver using minimal server specifications and Nginx will allow us to do that over Apache. (no debate intended, which is a better webserver)

### Work in progress
- Let's Encrypt SSL
- Database management
    + db (add, remove)
    + user (add, remove)

### Future feature

- Run Nginx with Apache
    + Nginx runs proxy
    + Apache as backend
