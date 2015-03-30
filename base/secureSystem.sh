#!/bin/bash
# This script will change a few configurations to secure the server ( just a little )

# Let's harden the door
sed -i 's:Port 22:Port 8585:g' /etc/network/interfaces
sudo service ssh reload