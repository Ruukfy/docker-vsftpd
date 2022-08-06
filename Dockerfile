FROM alpine:latest as pam_builder

RUN set -xe \
    && apk add -U build-base \
                  curl \
                  linux-pam-dev \
                  bsd-compat-headers \
                  sqlite-dev \
                  pam-pgsql \
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

FROM alpine:latest

LABEL Maintainer="" \
      Description="vsftpd Docker image based on Alpine. Supports passive mode and virtual users." \
      License="MIT License" \
      Version="3.0.3"

# if you want use APK mirror then uncomment, modify the mirror address to which you favor
# RUN sed -i 's|http://dl-cdn.alpinelinux.org|https://mirrors.aliyun.com|g' /etc/apk/repositories

ENV TZ=Europe/Madrid
RUN set -ex \
    && apk add --no-cache ca-certificates curl tzdata unzip vsftpd openssl nano python3 \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /tmp/* /var/cache/apk/*


ENV FTP_USER **String**
ENV FTP_PASS **Random**
ENV PASV_ADDRESS **IPv4**
ENV PASV_ADDR_RESOLVE NO
ENV PASV_ENABLE YES
ENV PASV_MIN_PORT 21000
ENV PASV_MAX_PORT 21010
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
ENV VIRTUAL_UID 1000
ENV VIRTUAL_GID 1000
ENV VIRTUAL_HOME /home/ftp/

COPY ./etc/vsftpd.conf /etc/vsftpd/
COPY ./etc/vsftpd.sh /usr/sbin/
COPY ./etc/vsftpd_manager.sh /usr/sbin/

COPY --from=pam_builder /lib/security/pam_pwdfile.so /lib/security/
COPY ./etc/pam/vsftpd_pwdfile /etc/pam.d/vsftpd_virtual

#COPY --from=pam_builder /lib/security/pam_sqlite3.so /lib/security/
#COPY ./etc/pam/pam_sqlite3.conf /etc/

#COPY --from=pam_builder /usr/lib/security/pam_pgsql.so /lib/security/
#COPY ./etc/pam/pam_pgsql.conf /etc/

RUN set -ex \
    && chmod +x /usr/sbin/vsftpd.sh \
    && chmod +x /usr/sbin/vsftpd_manager.sh \
    && mkdir -p /var/log/vsftpd/ \
    && mkdir -p /etc/vsftpd/users/conf/


RUN delgroup ping &&  \
    addgroup -S -g 999 vsftpd && \
    adduser -S -u 999 -G vsftpd vsftpd && \
    addgroup -S -g ${VIRTUAL_GID} virtual && \
    adduser -S -u ${VIRTUAL_UID} -G virtual virtual && \
    mkdir -p ${VIRTUAL_HOME} && \
    chown -R virtual:virtual ${VIRTUAL_HOME}

VOLUME /home/ftp
VOLUME /var/log/vsftpd

EXPOSE 20 21 ${PASV_MIN_PORT:-21000}-${PASV_MAX_PORT:-21010}
#ENTRYPOINT ["/bin/sh","-c","sleep infinity"]
CMD ["/usr/sbin/vsftpd.sh"]