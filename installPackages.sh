#!/bin/bash
# Let's configure the packages
# First of all, we have to configure the standard daemons/services
sh /etc/nginxCaching/base/baseConfig.sh

# Let's set a static script folder
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
if [ $(dpkg-query -W -f='${Status}' sudo 2>/dev/null | grep -c "ok installed") -eq 0 ]
then
#sudo package is not currently installed on this box
echo '[Error] Please install sudo before contniuing (apt-get install sudo)'
exit 1
fi
current_user=$(whoami)
if [ $(sudo -n -l -U ${current_user} 2>&1 | egrep -c -i "not allowed to run sudo|unknown user") -eq 1 ]
then
echo '[Error]: You need to run this script under an account that has access to sudo'
exit 1
fi

# before we will install all necessary packages, we'll create some folders
# we will use the following folder as default
mkdir -p /srv/changeme/html

# install services
# install the web proxy
echo '[apt-get] Install nginx'
sudo apt-get install nginx -y &> /dev/null

# ok, now we need the correct php version for nginx
echo '[apt-get] Install php5-fpm'
apt-get install php5-fpm -y &> /dev/null

# and yes, we need a mysql database management tool
apt-get install phpmyadmin -y &> /dev/null
# would you like to access the tool by your site? uncomment the next line ( default uncommented )
ln -s /usr/share/phpmyadmin /srv/changeme/html

# let's download the latest wordpress version to a secure location
# well.. first we need to create a directory ofcourse
mkdir -p /etc/nginxCaching/wordpress
# ok let's download now
wget -O http://wordpress.org/latest.tar.gz /etc/nginxCaching/wordpress/latest.tar.gz
# unpack the tar.gz
# code will come here

# let's move the default config to nginx
mv /etc/nginxCaching/configs/changeme /etc/nginx/sites-available/changeme
# let's move the modified nginx configuration
rm /etc/nginx/nginx.conf 
mv /etc/nginxCaching/configs/nginx.conf /etc/nginx/nginx.conf
# now we need a symbolic link
ln -s /etc/nginx/sites-available/changeme /etc/nginx/sites-enabled/
service nginx reload

# let's ask michael schumacher for help
sudo curl http://repo.varnish-cache.org/debian/GPG-key.txt | sudo apt-key add -
# the following line has not been tested yet
echo "deb http://repo.varnish-cache.org/ubuntu/ lucid varnish-3.0" >> /etc/apt/sources.list
# let's refresh our repo's
sudo apt-get update
# and install Varnish
sudo apt-get install varnish libvarnish-dev
# now we have to configure Varnish 
## lines here

# make installation done
# will create a better solution later on
mkdir /etc/nginxCaching/done


