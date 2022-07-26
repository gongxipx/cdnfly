#/bin/bash

#本脚本只适用于Centos7.x系列
#安装nginx函数
install_nginx(){
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
	#设置nginx开机启动
	systemctl enable nginx
	#开启nginx 服务
	systemctl start nginx
	##开放防火墙端口
	firewall-cmd --zone=public --add-port=22/tcp --permanent
	firewall-cmd --zone=public --add-port=80/tcp --permanent
	firewall-cmd --zone=public --add-port=443/tcp --permanent
	firewall-cmd --reload
	##写入nginx配置文件
	echo "server {
		listen 80;
		server_name ${domain} auth.cdnfly.cn monitor.cdnfly.cn;
		root /usr/share/nginx/html/${domain};
		index index.html index.htm index.php;
		location ~ [^/]\.php(/|$) {
			fastcgi_pass 127.0.0.1:9000;
			fastcgi_index index.php;
			fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
			include fastcgi_params;
		}
		location / {
			if (!-e \$request_filename){
				rewrite  ^(.*)$  /index.php/\$1  last;   break;
			}
		}
	}" > /etc/nginx/conf.d/${domain}.conf
}

#安装php74函数
install_php(){
	#添加php运行用户组
	groupadd -r www
	useradd -r -g www www
	#安装php7.4服务
	yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm 
	yum install -y php74-php-fpm php74-php-cli php74-php-bcmath php74-php-gd php74-php-json  php74-php-mbstring php74-php-mcrypt php74-php-mysqlnd php74-php-opcache php74-php-pdo php74-php-pecl-crypto php74-php-pecl-mcrypt php74-php-pecl-geoip php74-php-recode php74-php-snmp php74-php-soap php74-php-xml php74-php-imagick php74-php-pecl-zip
	#启动php74
	systemctl start php74-php-fpm
	#添加php74开机启动
	systemctl enable php74-php-fpm
	#修改php74配置文件
	sed -i "s/user = apache/user = www/g" /etc/opt/remi/php74/php-fpm.d/www.conf
	sed -i "s/group = apache/group = www/g" /etc/opt/remi/php74/php-fpm.d/www.conf
}

#下载web文件函数
dowload_webfile(){
	mkdir /usr/share/nginx/html/${domain}
	cd /usr/share/nginx/html/${domain}
	wget https://raw.githubusercontent.com/gongxipx/cdnfly/main/cdn/api.php
	wget https://raw.githubusercontent.com/gongxipx/cdnfly/main/cdn/config.php
	wget https://raw.githubusercontent.com/gongxipx/cdnfly/main/cdn/index.php
	wget https://raw.githubusercontent.com/gongxipx/cdnfly/main/cdn/monitor.php
	wget https://raw.githubusercontent.com/gongxipx/cdnfly/main/cdn/update.php
	sed -i "s#https://update.cdnfly.cn/master/upgrades?version_num=#http://${domain}/master/upgrades?version_num=#g" /usr/share/nginx/html/${domain}/update.php
	wget https://raw.githubusercontent.com/gongxipx/cdnfly/main/cdn/version.json
}

#函数执行模块
read -p "请输入cdnfly认证服务器绑定的域名:" domain
install_nginx
install_php
dowload_webfile
