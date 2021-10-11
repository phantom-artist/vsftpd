#!/bin/bash
#
# delftpdata.sh
#
# This script will remove a data directory for a virtual user, only if the virtual user account has first been removed using delftpuser.sh
#

DB_DIR=/etc/vsftpd/db

# Are you sure?
read -p "This is a destructive action that will remove the ftp data directory for a deactivated user permanently. Continue? [Y/N]: " RESPONSE

if [[ "$RESPONSE" =~ ^([yY])$ ]]; then

  read -p "Username: " USERNAME

  # Check user doesn't exist - we don't delete data directories for 'active' users
  if grep -Fxq "$USERNAME" $DB_DIR/virtual_users.txt
  then
    echo "Cannot delete directory for active user $USERNAME, please run delftpuser.sh first"
    exit 1
  fi

  # Delete user directory if it exists
  if [ -d /home/vsftpd/${USERNAME} ]; then
    rm -rf /home/vsftpd/${USERNAME}
    echo "Deleted directory for ${USERNAME}"
  else
    echo "${USERNAME} directory was not found"
  fi
else
  echo "No changes made"
  exit 0
fi
