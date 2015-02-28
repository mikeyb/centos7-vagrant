#!/bin/bash

# Execute Cakephp setup
curl -s https://raw.githubusercontent.com/mikeyb/centos7-vagrant/master/cakephp.sh?token=AACObUMzjVtJvC0oACzWqzPk-Axb4PjVks5U-v4iwA%3D%3D | bash

# Disable sendfile
# sendfile results in caching problems on VirtualBox
# http://abitwiser.wordpress.com/2011/02/24/virtualbox-hates-sendfile/
sed -i "s/^.*sendfile on;/sendfile off;/" /etc/nginx/nginx.conf
systemctl reload nginx.service

# symlink nginx html docroot to /web
rm -rf /usr/share/nginx/html
ln -fs /web /usr/share/nginx/html
mkdir /web

# Get us to latest
yum upgrade -y

# Show the versions of important software
cat /etc/redhat-release
nginx -v
php-fpm -v
mysql -V

echo ""
echo "Vag up!"
