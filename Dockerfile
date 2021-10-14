FROM centos:7

LABEL maintainer="phantom-artist"

ARG USER_ID=14
ARG GROUP_ID=50

RUN yum update -y && \
    yum install -y \
        vsftpd \
        db4-utils \
        db4 \
        iproute \
        openssl && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN usermod -u ${USER_ID} ftp
RUN groupmod -g ${GROUP_ID} ftp

ENV FTP_USER **String**
ENV FTP_PASS **Random**
ENV PASV_ADDRESS **IPv4**
ENV PASV_ADDR_RESOLVE NO
ENV PASV_ENABLE YES
ENV PASV_MIN_PORT 21100
ENV PASV_MAX_PORT 21110
ENV XFERLOG_STD_FORMAT NO
ENV LOG_STDOUT **Boolean**
ENV FILE_OPEN_MODE 0666
ENV LOCAL_UMASK 077
ENV REVERSE_LOOKUP_ENABLE YES
ENV PASV_PROMISCUOUS NO
ENV PORT_PROMISCUOUS NO

COPY vsftpd.conf /etc/vsftpd/
COPY vsftpd_virtual /etc/pam.d/
COPY run-vsftpd.sh /usr/sbin/
COPY addftpuser.sh /usr/sbin/
COPY modftpuser.sh /usr/sbin/
COPY delftpuser.sh /usr/sbin/
COPY delftpdata.sh /usr/sbin/

RUN mkdir -p /etc/vsftpd/db/
RUN chmod +x /usr/sbin/run-vsftpd.sh
RUN chmod +x /usr/sbin/addftpuser.sh
RUN chmod +x /usr/sbin/modftpuser.sh
RUN chmod +x /usr/sbin/delftpuser.sh
RUN chmod +x /usr/sbin/delftpdata.sh
RUN mkdir -p /home/vsftpd/
RUN chown -R ftp:ftp /home/vsftpd/

VOLUME /etc/vsftpd/db
VOLUME /home/vsftpd
VOLUME /var/log/vsftpd

EXPOSE 20 21

CMD ["/usr/sbin/run-vsftpd.sh"]
