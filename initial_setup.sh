#!/bin/bash

##
## USAGE
## bash <(curl -s https://raw.githubusercontent.com/mattmaddux/DigitalOceanScripts/main/initial_setup.sh)
##

echo "##### Updating Packages #####"

DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -y

echo "##### Setting Up User #####"

# Prompt for username and pass
read -p 'Username: ' user
read -sp 'Password: ' pass


# Create user and set password
adduser --disabled-password --gecos "" "$user"
echo "$pass" | passwd "$user"

# Add to sudo-ers list
usermod -aG sudo "$user"

# Setup ssh keys
mkdir /home/"$user"/.ssh
cp /root/.ssh/authorized_keys /home/"$user"/.ssh
chown "$user":"$user" -R /home/"$user"/.ssh
chmod 700 /home/"$user"/.ssh
chmod 600 /home/"$user"/.ssh/authorized_keys

# Allow sudo without password
cp /etc/sudoers /tmp/sudoers.new
echo "$user ALL=(ALL) NOPASSWD: ALL" >> /tmp/sudoers.new
visudo -c -f /tmp/sudoers.new
if [ "$?" -eq "0" ]; then
    cp /tmp/sudoers.new /etc/sudoers
fi


echo "##### Enabling UFW Firewall #####"
ufw allow OpenSSH
ufw --force enable



echo "##### Disabling Root Login #####"

FILE="/etc/ssh/sshd_config"
FIND="PermitRootLogin yes"
REPLACE="PermitRootLogin no"

sed -i "s/$FIND/$REPLACE/" $FILE

echo "##### Rebooting #####"

reboot