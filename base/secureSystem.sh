#!/bin/bash
# This script will change a few configurations to secure the server ( just a little )

# Let's harden the door
sed -i 's/8585/22/g' /etc/network/interfaces