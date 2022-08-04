#!/bin/sh
#
#echo "VSFTPD start"
#
##echo "SETUP DSN ${PAM_DSN}"
##
##echo "connect=${PAM_DSN}" >> /etc/pam_pgsql.conf
#
## Set passive mode parameters:
#if [ "$PASV_ADDRESS" = "**IPv4**" ]; then
#    PASV_ADDRESS=$(/sbin/ip route|awk '/default/ { print $3 }')
#    export PASV_ADDRESS
#fi
#
#echo "" >> /etc/vsftpd/vsftpd.conf
#echo "###" >> /etc/vsftpd/vsftpd.conf
#echo "### Variables set at container runtime" >> /etc/vsftpd/vsftpd.conf
#echo "###" >> /etc/vsftpd/vsftpd.conf
#echo "" >> /etc/vsftpd/vsftpd.conf
#
#echo "pasv_address=${PASV_ADDRESS}" >> /etc/vsftpd/vsftpd.conf
#echo "pasv_max_port=${PASV_MAX_PORT}" >> /etc/vsftpd/vsftpd.conf
#echo "pasv_min_port=${PASV_MIN_PORT}" >> /etc/vsftpd/vsftpd.conf
#echo "pasv_addr_resolve=${PASV_ADDR_RESOLVE}" >> /etc/vsftpd/vsftpd.conf
#echo "pasv_enable=${PASV_ENABLE}" >> /etc/vsftpd/vsftpd.conf
#echo "file_open_mode=${FILE_OPEN_MODE}" >> /etc/vsftpd/vsftpd.conf
#echo "local_umask=${LOCAL_UMASK}" >> /etc/vsftpd/vsftpd.conf
#echo "xferlog_std_format=${XFERLOG_STD_FORMAT}" >> /etc/vsftpd/vsftpd.conf
##echo "reverse_lookup_enable=${REVERSE_LOOKUP_ENABLE}" >> /etc/vsftpd/vsftpd.conf
#echo "pasv_promiscuous=${PASV_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf
#echo "port_promiscuous=${PORT_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf
#
## Add ssl options
#if [ "$SSL_ENABLE" = "YES" ]; then
#	echo "ssl_enable=YES" >> /etc/vsftpd/vsftpd.conf
#	echo "allow_anon_ssl=NO" >> /etc/vsftpd/vsftpd.conf
#	echo "force_local_data_ssl=YES" >> /etc/vsftpd/vsftpd.conf
#	echo "force_local_logins_ssl=YES" >> /etc/vsftpd/vsftpd.conf
#	echo "ssl_tlsv1=YES" >> /etc/vsftpd/vsftpd.conf
#	echo "ssl_sslv2=NO" >> /etc/vsftpd/vsftpd.conf
#	echo "ssl_sslv3=NO" >> /etc/vsftpd/vsftpd.conf
#	echo "require_ssl_reuse=YES" >> /etc/vsftpd/vsftpd.conf
#	echo "ssl_ciphers=HIGH" >> /etc/vsftpd/vsftpd.conf
#	echo "rsa_cert_file=/etc/vsftpd/cert/$TLS_CERT" >> /etc/vsftpd/vsftpd.conf
#	echo "rsa_private_key_file=/etc/vsftpd/cert/$TLS_KEY" >> /etc/vsftpd/vsftpd.conf
#fi
#
#/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf

#!/bin/sh

# If no env var for FTP_USER has been specified, use 'admin':
if [ "$FTP_USER" = "**String**" ]; then
  export FTP_USER='admin'
fi

# If no env var has been specified, generate a random password for FTP_USER:
if [ "$FTP_PASS" = "**Random**" ]; then
  export FTP_PASS=`cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c${1:-16}`
fi

# Set passive mode parameters:
if [ "$PASV_ADDRESS" = "**IPv4**" ]; then
  export PASV_ADDRESS=$(curl -s -4 --connect-timeout 5 --max-time 10 ifconfig.co)
fi


echo -e "\n###\n### Variables set at container runtime ###\n###\n" >> /etc/vsftpd/vsftpd.conf

echo "pasv_address=${PASV_ADDRESS}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=${PASV_MAX_PORT}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=${PASV_MIN_PORT}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_addr_resolve=${PASV_ADDR_RESOLVE}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_enable=${PASV_ENABLE}" >> /etc/vsftpd/vsftpd.conf
echo "file_open_mode=${FILE_OPEN_MODE}" >> /etc/vsftpd/vsftpd.conf
echo "local_umask=${LOCAL_UMASK}" >> /etc/vsftpd/vsftpd.conf
echo "xferlog_std_format=${XFERLOG_STD_FORMAT}" >> /etc/vsftpd/vsftpd.conf
#echo "reverse_lookup_enable=${REVERSE_LOOKUP_ENABLE}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_promiscuous=${PASV_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf
echo "port_promiscuous=${PORT_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf

# Execute add ftp user script
if [ -n "$ADD_FTP_USER_SCRIPT" ] && [ ! -s "/etc/vsftpd/virtual_users" ]; then
  if [ -s "/etc/vsftpd/vsftpd-add-ftp-user.sh" ]; then
    chmod +x /etc/vsftpd/vsftpd-add-ftp-user.sh
    /etc/vsftpd/vsftpd-add-ftp-user.sh
  fi
fi

# fix ftp home permissions
chown -R virtual:virtual /home/ftp/

# Run vsftpd:
/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf