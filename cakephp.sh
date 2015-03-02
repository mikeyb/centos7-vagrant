#!/bin/bash

##
## Packages ##
##

# Yum Priorities
yum -y install yum-priorities epel-release

# Stuff we like ddddand need
yum -y install htop git curl vim

# nginx repo
yum -y install  http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

# Nginx/php/memcached
yum -y install nginx php-fpm php-gd php-mysql php-mcrypt php-pecl-apcu php-cli memcached php-pecl-memcache php-xml php-pecl-xdebug

# Percona mysql - dafuq is mariadb
rpm --import http://www.percona.com/downloads/RPM-GPG-KEY-percona
yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
yum -y install Percona-Server-server-56 Percona-Server-client-56 Percona-Server-shared-56 percona-xtrabackup percona-toolkit

# composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

##
## Configuration ##
##

# web user
useradd www -M # setup user

mkdir /web
chown vagrant:www /web
mount -t vboxsf -o uid=`id -u vagrant`,gid=`getent group www | cut -d: -f3`,dmode=775,fmode=775 web /web
mount -t vboxsf -o uid=`id -u vagrant`,gid=`id -g www`,dmode=775,fmode=775 web /web

# memcached
cat > /etc/sysconfig/memcached <<"EOF"
PORT="11211"
USER="memcached"
MAXCONN="256"
CACHESIZE="64"
OPTIONS="-a 666 -s /var/run/memcached/memcached.sock"
EOF

# allow uploads
chown -R www:www /var/lib/nginx 

# clean default docroot
rm -rf /usr/share/nginx/html/*

# php.ini
cat > /etc/php.ini <<"EOF"
[PHP]
engine = On
short_open_tag = Off
asp_tags = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 17
disable_functions =
disable_classes =
zend.enable_gc = On
expose_php = Off
max_execution_time = 30
max_input_time = 60
memory_limit = 128M

error_reporting = E_ALL
display_errors = On
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On

variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 8M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"

doc_root =
user_dir =
enable_dl = Off
cgi.fix_pathinfo=0

file_uploads = On
upload_max_filesize = 8M
max_file_uploads = 20

allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60

[CLI Server]
cli_server.color = On

[Date]
date.timezone = "America/New_York"

[Pdo_mysql]
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=

[Phar]
;phar.readonly = On
;phar.require_hash = On
;phar.cache_list =

[mail function]
SMTP = localhost
smtp_port = 25
sendmail_path = /usr/sbin/sendmail -t -i
mail.add_x_header = On

[SQL]
sql.safe_mode = Off

[mbstring]
mbstring.func_overload = 0

[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1

[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
ibase.dateformat = "%Y-%m-%d"
ibase.timeformat = "%H:%M:%S"

[MySQL]
mysql.allow_local_infile = On
mysql.allow_persistent = On
mysql.cache_size = 2000
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off

[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off

[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off

[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0

[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10

[bcmath]
bcmath.scale = 0

[Session]
session.save_handler = memcache
session.save_path = unix:/var/run/memcached/memcached.sock
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.bug_compat_42 = Off
session.bug_compat_warn = Off
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"

[Tidy]
tidy.clean_output = Off

[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5

[ldap]
ldap.max_links = -1

; Local Variables:
; tab-width: 4
; End:
EOF

cat > /etc/php-fpm.d/www.conf <<"EOF"
; Start a new pool named 'www'.
[www]

listen = /var/run/php-fpm/php-fpm.sock
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 6

slowlog = /var/log/php-fpm/www-slow.log
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
EOF

# apcu.ini
cat > /etc/php.d/apcu.ini <<"EOF"
extension = apcu.so
apc.enabled=1
apc.enable_cli=1
apc.shm_size=32M
apc.ttl=3600
apc.gc_ttl=3600
apc.smart=0
apc.entries_hint=4096
apc.mmap_file_mask=/tmp/apc.XXXXXX
EOF

# nginx fastcgi_params
cat > /etc/nginx/fastcgi_params <<"EOF"
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;

fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;

fastcgi_buffer_size 128k;
fastcgi_buffers 4 256k;
fastcgi_busy_buffers_size 256k;
EOF

# nginx php-sock.conf
cat > /etc/nginx/conf.d/php-sock.conf <<"EOF"
upstream php-fpm-sock {
    server unix:/var/run/php-fpm/php-fpm.sock;
}
EOF

# nginx default.conf
cat > /etc/nginx/conf.d/default.conf <<"EOF"
server {
  listen 80 default_server;
  server_name _;
  root /web/project/app/webroot;
  
  index index.php;
  try_files $uri $uri/ /index.php?$args;  

  location ~ \.php$ {
    try_files $uri =404;

    include fastcgi_params;
    fastcgi_pass php-fpm-sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_intercept_errors on;
  }

  location ~ /(\.ht|\.git|\.svn) {
        deny all;
  }
}
EOF

# nginx nginx.conf
cat > /etc/nginx/nginx.conf <<"EOF"
user                www;
worker_processes    2;
pid                 /var/run/nginx.pid;

events {
    worker_connections  768;
    #multi_accept on;
}

http {
    
    ##
    # Mime types
    ##
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    ##
    # Logging settings
    ##
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    error_log  /var/log/nginx/error.log  notice;
    #access_log  /var/log/nginx/access.log  main;

    ##
    # Default file to open
    ##
    index index.php index.html;

    ##
    # More over: http://technosophos.com/content/nginx-tcpnopush-sendfile-and-memcache-right-configuration?page=1
    # And: http://articles.slicehost.com/2008/5/15/ubuntu-hardy-nginx-configuration/
    ##
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    ##
    # Security
    ##
    server_tokens off;

    ##
    # How long a connection is kept open
    # And what to accept
    ##
    client_max_body_size  4096k; # Upload file cap
    client_header_timeout 10;
    client_body_timeout   10;
    keepalive_timeout     10 10;
    send_timeout          10;

    ##
    # Gzip compresses certain responses
    ##
    gzip                on;
    gzip_disable        "msie6";
    gzip_min_length     1100;
    gzip_vary           on;
    gzip_proxied        any;
    gzip_buffers        16 8k;
    gzip_types          text/plain text/css application/json application/x-javascript
                        text/xml application/xml application/rss+xml text/javascript
                        image/svg+xml application/x-font-ttf font/opentype
                        application/vnd.ms-fontobject;
    
    ##
    # Load config files from the /etc/nginx/conf.d directory
    # The default server is in conf.d/default.conf
    ##
    include /etc/nginx/conf.d/*.conf;

}
EOF


# mysql my.cnf
cat > /etc/my.conf <<"EOF"
[mysql]

# CLIENT #
port                           = 3306
socket                         = /var/lib/mysql/mysql.sock

[mysqld]

# GENERAL #
user                           = mysql
default-storage-engine         = InnoDB
socket                         = /var/lib/mysql/mysql.sock
pid-file                       = /var/lib/mysql/mysql.pid

# MyISAM #
key-buffer-size                = 32M
myisam-recover                 = FORCE,BACKUP

# SAFETY #
max-allowed-packet             = 16M
max-connect-errors             = 1000000

# DATA STORAGE #
datadir                        = /var/lib/mysql/

# BINARY LOGGING #
log-bin                        = /var/lib/mysql/mysql-bin
expire-logs-days               = 14
sync-binlog                    = 1

# CACHES AND LIMITS #
tmp-table-size                 = 32M
max-heap-table-size            = 32M
query-cache-type               = 0
query-cache-size               = 0
max-connections                = 150
thread-cache-size              = 16
open-files-limit               = 65535
table-definition-cache         = 1024
table-open-cache               = 2048

# INNODB #
innodb-flush-method            = O_DIRECT
innodb-log-files-in-group      = 2
innodb-log-file-size           = 32M
innodb-flush-log-at-trx-commit = 1
innodb-file-per-table          = 1
innodb-buffer-pool-size        = 512M

# LOGGING #
log-error                      = /var/lib/mysql/mysql-error.log
log-queries-not-using-indexes  = 1
slow-query-log                 = 1
slow-query-log-file            = /var/lib/mysql/mysql-slow.log
EOF

# disable sendfile - # http://abitwiser.wordpress.com/2011/02/24/virtualbox-hates-sendfile/
sed -i "s/^.*sendfile on;/sendfile off;/" /etc/nginx/nginx.conf

# disable selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/" /etc/selinux/config

# For autostart on reboot
systemctl enable memcached.service
systemctl enable php-fpm.service
systemctl enable nginx.service
systemctl enable mysqld.service

# Start them up now
systemctl start php-fpm.service
systemctl start memcached.service
systemctl start nginx.service
systemctl start mysqld.service

# secure mysql and add vagrant user
mysql -u root <<"EOF"
GRANT ALL PRIVILEGES ON *.* TO vagrant@'%' IDENTIFIED BY "datpassword" WITH GRANT OPTION;
DROP DATABASE test;
DELETE FROM mysql.user WHERE User='root' AND Host!='localhost';
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
EOF

# set mysql root password
mysqladmin -u root password 'datpassword'

firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload

chown -R root:www /etc/nginx/conf.d/
chmod -R g+w /etc/nginx/conf.d/

chown -R root:www /etc/php.d/
chmod -R g+w /etc/php.d/

chown -R root:www /etc/php-fpm.d/
chmod -R g+w /etc/php-fpm.d/

echo ""
echo ""
echo "Ship It!"
