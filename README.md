# vsftpd
Docker image for running a vsftpd container using virtual users, based on the excellent work at [fauria / docker-vsftpd](https://github.com/fauria/docker-vsftpd)
Check that solution for a detailed list of settings that can be applied to this image at runtime.

The main differences are that this solution attempts to build on docker-vsftpd to allow permanent storage of users / data on volumes which persists across the lifecycle of the container.

**SECURITY WARNING**: FTP is not a secure protocol and 'crypt' is not a secure function by today's standards. If you want robust security around your users and data, do not use vsftpd and opt for a sftp-based solution where strong encryption and key-based authentication can be implemented.

This is definitely a "use-at-your-own-risk" solution, primarily done as an exercise, and I accept no liability for the security of your data if you implement this solution  :)

## Build
<code>
docker build -t my-ftp .
</code>

## Example Run
    docker run -d --name my-ftp \
    -p8020:20 \
    -p8021:21 \
    -p 21100-21110:21100-21110 \
    -e PASV_MIN_PORT=21100 \
    -e PASV_MAX_PORT=21110 \
    -e PASV_ADDRESS=< host IP > \
    -v /path/to/volume/users:/etc/vsftpd/db \
    -v /path/to/volume/log:/var/log/vsftpd \
    -v /path/to/volume/data:/home/vsftpd \
    my-ftp

## Add A User
<code>
docker exec -ti my-ftp /bin/bash

addftpuser.sh
</code>
  
## Change A User Password
<code>
docker exec -ti my-ftp /bin/bash

modftpuser.sh
</code>
  
## Delete A User Account (not the data)
<code>
docker exec -ti my-ftp /bin/bash

delftpuser.sh
</code>

## Delete A User's Data (can only be run after delftpuser.sh)
<code>
docker exec -ti my-ftp /bin/bash

delftpdata.sh
</code>
  
## Connect to FTP Service
<code>
ftp host-running-the-container 8021
</code>
