cat << EOF >> /etc/environment
http_proxy=http://cacheserver1:8080
https_proxy=http://cacheserver1:8080
ftp_proxy=http://cacheserver1:8080
HTTP_PROXY=http://cacheserver1:8080
HTTPS_PROXY=http://cacheserver1:8080
FTP_PROXY=http://cacheserver1:8080
EOF

echo >> /etc/hosts
echo "127.0.0.1 turn.goto-rtc.com" >> /etc/hosts

echo >> /etc/ntp.conf
echo "pool ntp.zkrd.de" >> /etc/ntp.conf
