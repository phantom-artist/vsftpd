#!/bin/bash
#
# delftpuser.sh
#
# This script will remove a virtual user from the virtual_users.db
# To try and prevent concurrent modifications, a lock file is created around the most destructive process
#
DB_DIR=/etc/vsftpd/db
LOCK_FILE=$DB_DIR/db.lock

# Are you sure?
read -p "This is a destructive action that will delete the ftp user permanently. Continue? [Y/N]: " RESPONSE

if [[ "$RESPONSE" =~ ^([yY])$ ]]; then

  read -p "Username: " USERNAME

  # Check user exists
  if grep -Fxq "$USERNAME" $DB_DIR/virtual_users.txt
  then

    # Check for lock file
    if [ -f "$LOCK_FILE" ]; then
      echo "DB lock file exists. Please try again in a few seconds."
      exit 1
    fi

    touch $LOCK_FILE
    echo "Removing user $USERNAME"

    echo "Backing up existing virtual_users..."
    cp -p $DB_DIR/virtual_users.txt $DB_DIR/virtual_users.bk

    # Output the file contents through sed to delete the user line and it's password line
    cat $DB_DIR/virtual_users.txt | sed "/$USERNAME/,+1 d" > $DB_DIR/virtual_users.new

    # Eek - outside of using BerkleyDB programatic API, the only way to purge the user is to delete the whole db and reload from scratch using the new file
    rm -f $DB_DIR/virtual_users.db
    /usr/bin/db_load -T -t hash -f $DB_DIR/virtual_users.new $DB_DIR/virtual_users.db
    cp $DB_DIR/virtual_users.new $DB_DIR/virtual_users.txt
    rm -f $DB_DIR/virtual_users.new
    echo "Updated user database"
    rm -f $LOCK_FILE

    echo "If you wish to delete the user's ftp data directory run delftpdata.sh"

  else
    echo "User $USERNAME was not found. No changes made."
    exit 1
  fi
else
  echo "No changes made"
  exit 0
fi
