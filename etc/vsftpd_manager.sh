#!/bin/sh

mkdir -p "/home/ftp/$1" && chown -R virtual:virtual "/home/ftp/$1"

echo "$1:$(openssl passwd -1 $2)" >> /etc/vsftpd/users/virtual_users.pwdfile
