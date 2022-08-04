FROM alpine:3.15 as pam_builder

RUN set -xe \
    && apk add -U build-base \
                  curl \
                  linux-pam-dev \
                  bsd-compat-headers \
                  sqlite-dev \
                  tar \
    && mkdir pam_pwdfile \
        && cd pam_pwdfile \
        && curl -sSL https://github.com/tiwe-de/libpam-pwdfile/archive/v1.0.tar.gz | tar xz --strip 1 \
        && make install \
        && cd .. \
        && rm -rf pam_pwdfile \
    && mkdir pam_sqlite3 \
        && cd pam_sqlite3 \
        && curl -sSL https://github.com/HormyAJP/pam_sqlite3/archive/refs/tags/v1.0.2.tar.gz | tar xz --strip 1 \
        && ./configure && make && make install \
        && cd .. \
        && rm -rf pam_sqlite3 \
    && apk del build-base \
               curl \
               linux-pam-dev \
               bsd-compat-headers \
               sqlite-dev \
               tar

FROM alpine:3.15

ARG USER_ID=1000
ARG GROUP_ID=1000


LABEL Description="vsftpd Docker image based on Alpine. Supports passive mode, SSL and virtual users." \
	License="Apache License 2.0" \
	Usage="docker run -d -p [HOST PORT NUMBER]:21 -v [HOST FTP HOME]:/home/vsftpd whatever/vsftpd" \
	Version="1.0"

COPY --from=pam_builder /lib/security/pam_pwdfile.so /lib/security/
COPY --from=pam_builder /lib/security/pam_sqlite3.so /lib/security/

RUN apk update && apk upgrade && \
    apk --update add --no-cache vsftpd openssl iproute2 linux-pam db-utils pam-pgsql postgresql-client sqlite nano && \
    rm -f /var/cache/apk/*

RUN addgroup -S -g ${USER_ID} vsftpd && adduser -S -u ${GROUP_ID} -G vsftpd vsftpd

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
ENV SSL_ENABLE NO
ENV TLS_CERT cert.pem
ENV TLS_KEY key.pem


COPY etc/vsftpd.conf /etc/vsftpd/
COPY etc/users/ /etc/vsftpd/users/
COPY etc/pam/vsftpd_virtual /etc/pam.d/
COPY etc/vsftpd.sh /usr/sbin/
COPY etc/pam/*.conf /etc/
COPY etc/vsftpd_manager.sh /usr/sbin

RUN mkdir -p /etc/vsftpd/users/conf/

RUN chmod +x /usr/sbin/vsftpd.sh && \
    chmod +x /usr/sbin/vsftpd_manager.sh && \
    mkdir -p /home/vsftpd/ && \
    chown -R vsftpd:vsftpd /home/vsftpd/


VOLUME /home/vsftpd
VOLUME /var/log/vsftpd
VOLUME /etc/vsftpd/cert
VOLUME /etc/vsftpd/users

EXPOSE 20 21 21000-21010

CMD ["/usr/sbin/vsftpd.sh"]
#ENTRYPOINT ["/bin/sh","-c","sleep infinity"]
