#!/bin/bash
#===============================================================================================
#   System Required:  CentOS 6,7, Debian, Ubuntu
#   Description:  One click Install a powerful nginx based webserver
#	Extra's: Optimized for Wordpress multi-site
#   Author: Jay Maree <pm@me>
#   Intro:  github.com/jaymaree
#===============================================================================================
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root :(" 
    echo "Please try running this command again as root user"
    exit 1
fi

OS=$(awk '/DISTRIB_ID=/' /etc/*-release | sed 's/DISTRIB_ID=//' | tr '[:upper:]' '[:lower:]')
CODENAME=$(awk '/DISTRIB_CODENAME=/' /etc/*-release | sed 's/DISTRIB_CODENAME=//' | tr '[:upper:]' '[:lower:]')
PROCESS_COUNT=$(grep -c ^processor /proc/cpuinfo)
NGINX_PPA=0
MARIADB_VER="10.0"
PHP_VER="php5-oldstable"
#if [ "$OS" != "ubuntu" ] && [ "$OS" != "debian" ] && [ "$OS" != "mint" ]; then
if [ -f /usr/bin/apt-get ] && [ -f /usr/bin/aptitude ]; then
    echo "Detected $OS"
else
    echo "Warning: This script is made for Debian based Linux."
fi

function printMessage() {
    echo -e "\e[1;37m# $1\033[0m"
}

function apt_cache_update {
    printMessage "Updating APT(Advanced Packaging Tool) cache"
    apt-get update > /dev/null
}

function select_nginx {
        echo ""
        printMessage "Select NGINX PPA(Personal Package Archives)"
        echo "  1) Stable << Recommend"
        echo "  2) Development"
        echo -n "Enter: "
        read NGINX_PPA
        if [ "$NGINX_PPA" != 1 ] && [ "$NGINX_PPA" != 2 ]; then
            select_nginx
        fi
}

function select_php {
    echo ""
    printMessage "Select PHP version"
    echo "  1) 5.4"
    echo "  2) 5.5"
    echo "  3) 5.6"
    echo "  WARNING: Ubuntu 14.04 trusty does not support php-oldstable(5.4)"
    echo -n "Enter: "
    read PHP_SELECT
    if [ "$PHP_SELECT" != 1 ] && [ "$PHP_SELECT" != 2 ] && [ "$PHP_SELECT" != 3 ]; then
        select_php
    elif [ "$PHP_SELECT" == 1 ]; then
        PHP_VER="php5-oldstable"
    elif [ "$PHP_SELECT" == 2 ]; then
        PHP_VER="php5"
    elif [ "$PHP_SELECT" == 3 ]; then
        PHP_VER="php5-5.6"
    fi
}

function func_install {
    echo -en "\033[1mAre you sure want to continue? (y/n): \033[0m"
    read YN 
    YN=`echo $YN | tr "[:lower:]" "[:upper:]"`
    if [ "$YN" != "Y" ] && [ "$YN" != "N" ]; then
        func_install
    elif [ "$YN" == "N" ]; then
        exit
    fi
}

function install_nginx {
    printMessage "INSTALLING NGINX"
    
    [ "$NGINX_PPA" == 2 ] && NGINX_LW="development" || NGINX_LW="stable"
    
    add-apt-repository ppa:nginx/$NGINX_LW -y
    apt_cache_update
    apt-get install nginx -y
}

function install_php5 {
    printMessage "INSTALLING PHP5"
    
    add-apt-repository ppa:ondrej/$PHP_VER -y
    apt_cache_update
    apt-get install build-essential gcc g++ -y
    apt-get install libcurl3-openssl-dev -y
    apt-get install libpcre3 -y
    apt-get install libpcre3-dev -y 
    apt-get install sqlite sqlite3 -y
    apt-get install php5-fpm php5-common php5-cgi php5-cli php5-fpm php5-gd php5-cli php5-mcrypt php5-tidy php5-curl php5-xdebug php5-sqlite -y
    apt-get install php5-intl php5-dev -y
    apt-get install php-pear -y

    # Fix dependency
    apt-get purge apache2 libapache2-mod-php5 -y

    # Install php5-apcu
    apt-get install php5-apcu -y
    if [[ $? > 0 ]]; then
        apt-get install php-apc -y
    fi
}

function install_mysql {
    printMessage "INSTALLING MYSQL"
    
    apt_cache_update
    apt-get install -y mysql-server

    printMessage "INSTALLING PHP5-MySQL"
    apt-get install -y php5-mysql
	apt-get install -y phpmyadmin
}

function setting_nginx {
    printMessage "SETTING UP NGINX"
    
script_dir="/etc/nginxCaching/done"
if [ -d "$script_dir" ];
then
echo 'The nginxCaching folder exist already, please delete the folder and start over. If you update nginxCaching with new configuration files the installer may crash.'
exit 1
else
sudo wget https://raw.githubusercontent.com/JayMaree/nginxCaching/beta/configs/changeme -O /etc/nginxCaching/configs/changeme
sudo wget https://raw.githubusercontent.com/JayMaree/nginxCaching/beta/configs/nginx.conf -O /etc/nginxCaching/configs/nginx.conf
# and all the other configs
fi
mkdir -p /srv/changeme/html
ln -s /usr/share/phpmyadmin /srv/changeme/html
# let's move the default config to nginx
mv /etc/nginxCaching/configs/changeme /etc/nginx/sites-available/changeme
# let's move the modified nginx configuration
rm /etc/nginx/nginx.conf 
mv /etc/nginxCaching/configs/nginx.conf /etc/nginx/nginx.conf
# now we need a symbolic link
ln -s /etc/nginx/sites-available/changeme /etc/nginx/sites-enabled/
service nginx reload
}

function setting_wordpress {
    printMessage "SETTING UP WORDPRESS"
    
# let's download the latest wordpress version to a secure location
# well.. first we need to create a directory ofcourse
mkdir -p /etc/nginxCaching/downloads
# ok let's download now
wget http://wordpress.org/latest.tar.gz 
# unpack the tar.gz
# code will come here
tar -C /srv/changeme/html -xvzf /etc/nginxCaching/latest.tar.gz
}

function install_varnish {
    printMessage "INSTALLING VARNISH"
    
# let's ask michael schumacher for help
curl http://repo.varnish-cache.org/debian/GPG-key.txt | sudo apt-key add -
# the following line has not been tested yet
echo "deb http://repo.varnish-cache.org/ubuntu/ lucid varnish-3.0" >> /etc/apt/sources.list
# let's refresh our repo's
apt-get update
# and install Varnish
apt-get install - libvarnishapi1
apt-get install -y libvarnish1
apt-get install -y varnish
# now we have to configure Varnish 
## config lines here...
rm /etc/default/varnish
sudo wget https://raw.githubusercontent.com/JayMaree/nginxCaching/beta/configs/varnish -O /etc/default/varnish
rm /etc/varnish/default.vcl
sudo wget https://raw.githubusercontent.com/JayMaree/nginxCaching/beta/configs/default.vcl -O /etc/varnish/default.vcl
rm /etc/nginx/sites-enabled/default

chown root:www-data /srv/changeme/html
chmod 775 /srv/changeme/html
echo "Does the website work?" > /srv/changeme/html/index.html
mkdir /etc/nginxCaching/done
}

clear
echo "---------------------------------------------------------------"
echo -e "# Welcome to \033[1mNGINX+PHP+MariaDB\033[0m Installer for Ubuntu/Debian!"
echo "---------------------------------------------------------------"
select_nginx
select_php

echo ""
echo "---------------------------------------------------------------"
echo "Here are install option you have selected:"
NGX_COMMENT="NGINX"
[ "$NGINX_PPA" == 1 ] && NGX_VER="Stable" || NGX_VER="Development"
echo "  $NGX_COMMENT $NGX_VER"
echo "  PHP stable (The latest version) + PHP Extensions"
echo "  MySQL 5.5"
echo "---------------------------------------------------------------"
echo ""
func_install
install_nginx
install_php5
install_mysql

printMessage "Stopping Nginx service"
service nginx stop

printMessage "Configuring nginx and setting up Wordpress"
setting_nginx
setting_wordpress

printMessage "Installing varnish"
install_varnish

printMessage "Starting nginx/php5-fpm/mysql service"
service nginx start
service php5-fpm restart
service mysql restart
service varnish restart

echo ""
clear
echo "---------------------------------------------------------------"
echo -e "\033[34m # Installed \033[1mNGINX+PHP+MySQL+Varnish\033[0m.\033[0m"
echo "---------------------------------------------------------------"
echo "* NGINX: service nginx {start|stop|restart|reload|status}"
echo "  /etc/nginx/"
echo "* PHP: service php5-fpm {start|stop|restart|status}"
echo "  /etc/php5/php5-fpm/"
echo "* MySQL: service mysqld {start|stop|restart|status}"
echo "  /etc/mysql/"
echo "---------------------------------------------------------------"
echo "* phpMyAdmin: http://localhost/phpmyadmin"
echo "---------------------------------------------------------------"
echo -e "\033[37m  NGINX+PHP+MySQL by Jay Maree(pm@me)\033[0m"
echo "---------------------------------------------------------------"
