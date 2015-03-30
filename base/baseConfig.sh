#!/bin/bash
# This script will prepare the Digital Ocean VM with the base of debian
# beta repo 0.1

# The apt-get update command is used to re-synchronize the package index files from their sources.
# If used in combination with the apt-get upgrade command, they install the newest versions of
# all packages currently available.
# Let's update the base sytem
apt-get update && apt-get upgrade

# Fasten your seat belts!
# Google should be fine!
sed -i 's/8.8.8.8/208.67.220.220/g' /etc/network/interfaces
sed -i 's/8.8.4.4/8.8.8.8/g' /etc/network/interfaces

# We could use the firewall config to allow several ports
# and block the others
# Remove the following two hashtags if it needs to be enabled
#cp /etc/base/firewall.rules /etc/firewall.rules
##update-rc.d myfirewall start 40 S . stop 89 0 6 .
#iptables-restore < /etc/firewall.rules
#iptables-save > /etc/firewall.rules
#cp /etc/iptables /etc/network/if-pre-up.d/iptables
#chmod +x /etc/network/if-pre-up.d/iptables

# let's block the bruteforcers
# see https://www.howtoforge.com/preventing_ssh_dictionary_attacks_with_denyhosts
apt-get install denyhosts -y
# let's change the config the the most secured values
sed -i 's/DENY_THRESHOLD_VALID = 10/DENY_THRESHOLD_VALID = 1/g' /etc/denyhosts.conf
sed -i 's/DENY_THRESHOLD_ROOT = 5/DENY_THRESHOLD_ROOT = 1/g' /etc/denyhosts.conf
# let's use the new config, this will restart the denyhosts service
service denyhosts restart

# let's install fail2ban for automated bans
#apt-get install fail2ban -y
# setup the configuration
# see http://www.pontikis.net/blog/fail2ban-install-config-debian-wheezy