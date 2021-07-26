#!/bin/bash

# Used to filter database name from its full system path
# (1)/var(2)/lib(3)/mysql(4)/dbname(5)
AWK_DB_POS="5"

source ./options.conf

function find_available_databases {

  # Initialize variable
  DATABASES_AVAILABLE=0

  # First search for available mysql databases
  find /var/lib/mysql/* -maxdepth 0 -type d > /tmp/database.txt

  # Remove mysql and phpmyadmin as available databases
  sed -i '/\/var\/lib\/mysql\/mysql/ d' /tmp/database.txt
  sed -i '/\/var\/lib\/mysql\/phpmyadmin/ d' /tmp/database.txt
  DATABASES_AVAILABLE=`cat /tmp/database.txt | wc -l`

  # No databases found, ask user to add database first
  if [ $DATABASES_AVAILABLE -eq 0 ]; then
    echo "No database found. Please add a database first."
    exit
  fi

} # End of find_available_databases

function add_database {

  echo "Enter database name: "
  read DATABASE_NAME

  CHECK_DB="$(mysql -sse "SELECT EXISTS(SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='${DATABASE_NAME}');")"
  if [ "$CHECK_DB" -eq 1 ]; then
    echo "Sorry, that databse already exist!"
  else
    # add database
    mysql -e "CREATE DATABASE \`${DATABASE_NAME}\`;"

    # Throw success message
    echo ""
    echo -e " New \033[36m\"$DATABASE_NAME\"\033[0m database has been added!"
    echo ""
  fi

} # End of add_database

function remove_database {

  # Initialize selection value when listing available databases to user
  counter=1
  # Check how many databases are available
  DB_AVAILABLE=`cat /tmp/database.txt | wc -l`

  # Print out available databases
  echo ""
  echo "Select the database you want to drop, 1 to $DB_AVAILABLE"
  while read LINE; do
    # Get only the database name and leave out the full path
    data=`echo $LINE | awk -F"/" '{ print $'${AWK_DB_POS}' }'`
    echo "$counter. $data"
    # Increment counter for next iteration
    let counter+=1
  done < "/tmp/database.txt"

  # Reduce counter by 1 for next function
  let counter-=1

  # Ensure that the user inputs a valid integer
  # Initialize variable with a alphabet
  SELECTDB="a"

  # Keep on looping until input is a number that is greater than 0 and less than the number of available databases
  until  [[ "$SELECTDB" =~ [0-9]+ ]] && [ $SELECTDB -gt 0 ] && [ $SELECTDB -le $counter ]; do
    echo ""
    echo -n "Choose [integer]: "
    read SELECTDB
  done

  # Capture database name from its full path using AWK
  DATABASE=`cat /tmp/database.txt | awk NR==$SELECTDB | awk -F"/" '{ print $'${AWK_DB_POS}' }'`

  echo -e "\033[31;1mWARNING: This will permanently delete \"$DATABASE\"\033[0m"
  echo -e "\033[31mIf you wish to stop it, press \033[1mCTRL+C\033[0m \033[31mto abort.\033[0m"
  sleep 10
  # remove database
  mysql -e "DROP DATABASE \`${DATABASE}\`;"

  echo ""
  echo -e "Database name \033[36m\"$DATABASE\"\033[0m has been removed!"
  echo ""

  # Remove temporary file
  rm -rf /tmp/database.txt
}

function add_user {

  echo "Enter username: "
  read REG_USERNAME

  # Check if user exists
  CHECK_DB_USER="$(mysql -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user='$REG_USERNAME');")"

  if [[ $CHECK_DB_USER -eq 1 ]]; then
    # If user exists throw this message
    echo "Sorry, that username already exists!"
  else
    echo "Enter password: "
    read -s REG_PASSWORD

    # creating user
    mysql -e "CREATE USER '${REG_USERNAME}'@'localhost' IDENTIFIED BY '${REG_PASSWORD}';"

    # granting privileges
    mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,REFERENCES,DROP,CREATE,ALTER,INDEX ON *.* TO '${REG_USERNAME}'@localhost IDENTIFIED BY '${REG_PASSWORD}';"

    # Finalize the permissions
    mysql -e "FLUSH PRIVILEGES;"
    # Throw success message
    echo ""
    echo -e " New \033[36m\"$REG_USERNAME\"\033[0m user has been added!"
    echo ""
  fi

} # End of add_reg_user

function add_super_user {

  echo "Enter SUPER username: "
  read SUPER_USERNAME

  # Check if user exists
  CHECK_DB_SUPER_USER="$(mysql -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user='$SUPER_USERNAME');")"

  if [[ $CHECK_DB_SUPER_USER -eq 1 ]]; then
    # If user exists throw this message
    echo "Sorry, that SUPER username already exists!"
  else
    echo "Enter password: "
    read -s SUPER_PASSWORD

    # creating super user
    mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE,REFERENCES,DROP,CREATE,ALTER,INDEX ON *.* TO '${SUPER_USERNAME}'@'%' IDENTIFIED BY '${SUPER_PASSWORD}';"

    # granting privileges
    mysql -e "GRANT ALL privileges ON *.* TO '${SUPER_USERNAME}';"

    # Finalize the permissions
    mysql -e "FLUSH PRIVILEGES;"

    # Throw success message
    echo ""
    echo -e " New \033[36m\"$SUPER_USERNAME\"\033[0m SUPER user has been added!"
    echo ""
  fi

} # End of add_reg_user

function remove_user {

  echo "Enter username: "
  read USERNAME

  # Check if user exists
  CHECK_USER="$(mysql -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user='$USERNAME');")"

  if [[ $CHECK_USER -eq 0 ]]; then
    # If user exists throw this message
    echo "Sorry, that username does not exists!"
  else

    echo -e "\033[31;1mWARNING: This will permanently delete \"$USERNAME\"\033[0m"
    echo -e "\033[31mIf you wish to stop it, press \033[1mCTRL+C\033[0m \033[31mto abort.\033[0m"
    sleep 5

    # remove username
    mysql -e "DELETE FROM mysql.user WHERE user = '${USERNAME}';"

    #mysql -e "DROP USER IF EXISTS \'\'@\'\';"

    echo ""
    echo -e "User \033[36m\"$USERNAME\"\033[0m has been removed!"
    echo ""

  fi


} # End of remove_user

function list_users {

  mysql -e "SELECT user FROM mysql.user"

} # End of list_users

# Start main program
if [ ! -n "$1" ]; then
  echo ""
  echo -e "\033[35;1mSelect from the options below to use this script:- \033[0m"

  echo -n  "$0"
  echo -ne "\033[36m new db\033[0m"
  echo     " - Create new database"

  echo -n  "$0"
  echo -ne "\033[36m rem db\033[0m"
  echo     " - Destroy a database (cannot be undone)"

  echo -n  "$0"
  echo -ne "\033[36m new user\033[0m"
  echo     " - Create new user"

  echo -n  "$0"
  echo -ne "\033[36m new super_user\033[0m"
  echo     " - Create new SUPER user"

  echo -n  "$0"
  echo -ne "\033[36m rem user\033[0m"
  echo     " - Remove a user (cannot be undone)"

  echo ""
  exit
fi

case $1 in
add)
  if [ "$2" = "db" ]; then
    add_database
  elif [ "$2" = "user" ]; then
    add_user
  elif [ "$2" = "super_user" ]; then
    add_super_user
  fi
  ;;
rem)
  if [ "$2" = "db" ]; then
    find_available_databases
    remove_database
  elif [ "$2" = "user" ]; then
    remove_user
  fi
  ;;

list)
  if [ "$2" = "db" ]; then
    list_dbs
  elif [ "$2" = "users" ]; then
    list_users
  fi
  ;;
esac
