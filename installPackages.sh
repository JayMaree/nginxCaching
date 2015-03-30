#!/bin/bash
# Let's configure the packages
# First of all, we have to configure the standard daemons/services
sh /base/baseConfig.sh

# Let's set a static script folder
script_dir="/etc/nginxCaching"
if [ -d "$script_dir" ];
then
echo 'The nginxCaching folder exist already, please delete the folder and start over. If you update nginxCaching with new configuration files the installer may crash.'
exit
else
sudo wget https://raw.github.com/jaymaree/nginxCaching/beta/configs/default.conf -O /etc/nginxCaching/configs/default.conf
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

# install service
echo '[apt-get] Install nginx'
sudo apt-get install nginx &> /dev/null