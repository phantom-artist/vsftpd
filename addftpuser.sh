#!/bin/bash
#
# addftpuser.sh
#
# Add a new virtual user for ftp + create data directory
#
DB_DIR=/etc/vsftpd/db
LOCK_FILE=$DB_DIR/db.lock

read -p "Username to create: " USERNAME

# Check user doesn't already exist
if grep -Fxq "$USERNAME" $DB_DIR/virtual_users.txt
then
  echo "User $USERNAME already exists, please use modftpuser.sh to change the password or delftpuser.sh and delftpdata.sh to delete the user account and folder"
  exit 1
fi

# Generate unencrypted random password
PASSWORD=`cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c${1:-8}`
# We must encrypt the password to load it into the db
ENCRYPTED_PASSWORD=$(openssl passwd -crypt $PASSWORD)

# Check for lock file
if [ -f "$LOCK_FILE" ]; then
  echo "DB lock file exists. Please try again in a few seconds."
  exit 1
fi

touch $LOCK_FILE
# Write out the username/password to a temp file for db upload
echo -e "${USERNAME}\n${ENCRYPTED_PASSWORD}" > $DB_DIR/add_user.txt
/usr/bin/db_load -T -t hash -f $DB_DIR/add_user.txt $DB_DIR/virtual_users.db
# Delete the file so there is no permanent record of the generated password in plain-text
rm -f $DB_DIR/add_user.txt
# Add the user to the virtual_users permanent file (used for recreating the db)
if [ -f "$DB_DIR/virtual_users.txt" ]; then
  chmod u=rw $DB_DIR/virtual_users.txt
fi
echo -e "${USERNAME}\n${ENCRYPTED_PASSWORD}" >> $DB_DIR/virtual_users.txt
chmod u=r $DB_DIR/virtual_users.txt
echo "Created user $USERNAME"
rm -f $LOCK_FILE

# Create user ftp directory if it doesn't exist
if [ ! -d /home/vsftpd/${USERNAME} ]; then
  mkdir /home/vsftpd/${USERNAME}
  chown ftp:ftp /home/vsftpd/${USERNAME}
  echo "Created data directory for user $USERNAME"
fi

echo "Setting password $PASSWORD for user $USERNAME. Be sure to copy this password accurately, there is no way to retrieve it after exiting this session."
