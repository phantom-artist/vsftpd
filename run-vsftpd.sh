#!/bin/bash

# Do not log to STDOUT by default:
if [ "$LOG_STDOUT" = "**Boolean**" ]; then
    export LOG_STDOUT=''
else
    export LOG_STDOUT='Yes.'
fi

# Create home dir and update vsftpd user db:
mkdir -p "/home/vsftpd/"
chown -R ftp:ftp /home/vsftpd/

# Set passive mode parameters:
if [ "$PASV_ADDRESS" = "**IPv4**" ]; then
    export PASV_ADDRESS=$(/sbin/ip route|awk '/default/ { print $3 }')
fi

# Add config if not present (i.e. running container for first time)
export APPEND_CONFIG='Yes'
if grep -q "pasv_address=" /etc/vsftpd/vsftpd.conf
then
  APPEND_CONFIG='No'
else
  echo "pasv_address=${PASV_ADDRESS}" >> /etc/vsftpd/vsftpd.conf
  echo "pasv_max_port=${PASV_MAX_PORT}" >> /etc/vsftpd/vsftpd.conf
  echo "pasv_min_port=${PASV_MIN_PORT}" >> /etc/vsftpd/vsftpd.conf
  echo "pasv_addr_resolve=${PASV_ADDR_RESOLVE}" >> /etc/vsftpd/vsftpd.conf
  echo "pasv_enable=${PASV_ENABLE}" >> /etc/vsftpd/vsftpd.conf
  echo "file_open_mode=${FILE_OPEN_MODE}" >> /etc/vsftpd/vsftpd.conf
  echo "local_umask=${LOCAL_UMASK}" >> /etc/vsftpd/vsftpd.conf
  echo "xferlog_std_format=${XFERLOG_STD_FORMAT}" >> /etc/vsftpd/vsftpd.conf
  echo "reverse_lookup_enable=${REVERSE_LOOKUP_ENABLE}" >> /etc/vsftpd/vsftpd.conf
  echo "pasv_promiscuous=${PASV_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf
  echo "port_promiscuous=${PORT_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf
fi

# Get log file path
export LOG_FILE=`grep vsftpd_log_file /etc/vsftpd/vsftpd.conf|cut -d= -f2`

# stdout server info:
if [ ! $LOG_STDOUT ]; then
cat << EOB
        *************************************************
        *                                               *
        *    vsftpd image                               *
        *                                               *
        *************************************************

        SERVER SETTINGS
        ---------------
        · Log file: $LOG_FILE
        · Redirect vsftpd log to STDOUT: $LOG_STDOUT.
        · Appended config at runtime: $APPEND_CONFIG
EOB
else
    /usr/bin/ln -sf /dev/stdout $LOG_FILE
fi

# Run vsftpd:
&>/dev/null /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
