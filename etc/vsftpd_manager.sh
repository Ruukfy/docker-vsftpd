#!/bin/sh

mkdir -p "/home/ftp/$1" && chown -R virtual:virtual "/home/ftp/$1"

echo "$1:$(openssl passwd -1 $2)" >> /etc/vsftpd/users/virtual_users.pwdfile
#mkdir -p /etc/vsftpd/users/conf
#cat > /etc/vsftpd/users/conf/$1 <<EOF
#anon_world_readable_only=NO
#write_enable=YES
#anon_upload_enable=YES
#anon_mkdir_write_enable=YES
#anon_other_write_enable=YES
#local_root=/home/vsftpd/$1
#EOF