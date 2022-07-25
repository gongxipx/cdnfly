#/bin/bash

#安装nginx服务
yum install yum-utils -y
echo '[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true' >/etc/yum.repos.d/nginx.repo
yum-config-manager --enable nginx-mainline
yum install nginx -y 
systemctl enable nginx
systemctl start nginx
##开放防火墙端口
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --reload

yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm 
yum install -y php74-php-fpm php74-php-cli php74-php-bcmath php74-php-gd php74-php-json  php74-php-mbstring php74-php-mcrypt php74-php-mysqlnd php74-php-opcache php74-php-pdo php74-php-pecl-crypto php74-php-pecl-mcrypt php74-php-pecl-geoip php74-php-recode php74-php-snmp php74-php-soap php74-php-xml php74-php-imagick php74-php-pecl-zip

systemctl start php74-php-fpm
#4.添加开机启动
systemctl enable php74-php-fpm
#5.查看版本
cp /usr/bin/php74 /usr/bin/php #如果不复制的话，所有的php 替换成php74
chmod +x /usr/bin/php #文件给与执行权限
php -v

groupadd -r www
useradd -r -g www www

sed -i "s/user = apache/user = www/g" /etc/php-fpm.d/www.conf
sed -i "s/group = apache/group = www/g" /etc/php-fpm.d/www.conf

systemctl start php-fpm
systemctl enable php-fpm

mkdir /etc/nginx/vhost
echo '
server {
	listen 80;
	server_name auth.suses.net;
        root /usr/share/nginx/html/auth.suses.net;
        index index.html index.htm index.php;
        location ~ [^/]\.php(/|$) {
        try_files $uri =404;
        root /usr/share/nginx/html/auth.suses.net;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
	}
	location / {
		if (!-e $request_filename){
			rewrite  ^(.*)$  /index.php/$1  last;   break;
		}
	}
}' > /etc/nginx/vhost/auth.suses.net.conf

