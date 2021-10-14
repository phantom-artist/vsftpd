#!/bin/bash
#
# modftpuser.sh
#
# Change an existing virtual user's password for ftp
#
DB_DIR=/etc/vsftpd/db
LOCK_FILE=$DB_DIR/db.lock

read -p "Username: " USERNAME

# Check user exists
if grep -Fxq "$USERNAME" $DB_DIR/virtual_users.txt
then

  # Generate unencrypted random password
  PASSWORD=`cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c${1:-8}`
  # We must encrypt the password to load it into the db
  ENCRYPTED_PASSWORD=$(openssl passwd -crypt $PASSWORD)

  # Check for lock file before modifying db
  if [ -f "$LOCK_FILE" ]; then
    echo "DB lock file exists. Please try again in a few seconds."
    exit 1
  fi

  touch $LOCK_FILE

  # This process avoids destroying/recreating the .db file completely like delftpuser.sh
  # Write out the username/password to a temp file for db upload
  echo -e "${USERNAME}\n${ENCRYPTED_PASSWORD}" > $DB_DIR/update_user.txt
  /usr/bin/db_load -T -t hash -f $DB_DIR/update_user.txt $DB_DIR/virtual_users.db
  # Delete the file so there is no permanent record of the generated password in plain-text
  rm -f $DB_DIR/update_user.txt
  # At this point the user's pw is updated in the db, now fix the .txt file used for full reloads
  # Backup the virtual_users.txt
  cp -p $DB_DIR/virtual_users.txt $DB_DIR/virtual_users.bk
  # Write the master list, minus the username + old password line to .mod file
  cat $DB_DIR/virtual_users.txt | sed "/$USERNAME/,+1 d" > $DB_DIR/virtual_users.mod
  chmod u=rw $DB_DIR/virtual_users.txt
  # Append the username + new password to the end of the .mod file
  echo -e "${USERNAME}\n${ENCRYPTED_PASSWORD}" >> $DB_DIR/virtual_users.mod
  chmod u=r $DB_DIR/virtual_users.txt
  # Overwrite the master .txt file file with the .mod file
  cp $DB_DIR/virtual_users.mod $DB_DIR/virtual_users.txt
  # Delete the .mod file
  rm -f $DB_DIR/virtual_users.mod
  # Remove the lock
  rm -f $LOCK_FILE

  # Create user ftp directory if it doesn't exist
  if [ ! -d /home/vsftpd/${USERNAME} ]; then
    echo "WARNING: User ${USERNAME} ftp directory was not found, this is unexpected. Creating data folder..."
    mkdir /home/vsftpd/${USERNAME}
    chown ftp:ftp /home/vsftpd/${USERNAME}
  fi

  echo "Setting password $PASSWORD for user $USERNAME. Be sure to copy this password accurately, there is no way to retrieve it after exiting this session."

else
  echo "User $USERNAME was not found, please use addftpuser.sh to add a user account"
  exit 1
fi
