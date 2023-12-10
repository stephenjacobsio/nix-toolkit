#!/bin/bash

set -e  # Exit on any error

# Update and Upgrade the System
apt-get update && apt-get upgrade -y

# Install Required Packages
# Including git and nginx in the installation list
apt-get install -y curl rsyslog ca-certificates gnupg sudo openssh-server ufw fail2ban git nginx

# Configure SSH
# Change the default SSH port to a non-standard port
sed -i 's/#Port 22/Port 584/' /etc/ssh/sshd_config
# Disable root login
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
# Enable key-based authentication
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# Restart SSH to apply changes
systemctl restart sshd

# Configure UFW (Uncomplicated Firewall)
ufw default deny incoming
ufw default allow outgoing
ufw allow 584/tcp    # Allowing your custom SSH port
ufw enable

# Configure Fail2Ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban

# Remove Any Existing Docker Packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    apt-get remove -y $pkg
done

# Add Docker's Official GPG Key
apt-get update
apt-get install -y ca-certificates gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker Repository to Apt Sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

# Install Docker and Related Components
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create and Configure a Non-Root User for Docker Management
USER_NAME="dockeruser"
adduser --disabled-password --gecos "" $USER_NAME
usermod -aG docker $USER_NAME

# Create a Sudo User for SSH Access
SUDO_USER="sudouser"
adduser --disabled-password --gecos "" $SUDO_USER
usermod -aG sudo $SUDO_USER

# Kernel Performance Tuning (Optional)
# echo 'net.ipv4.tcp_fin_timeout = 30' >> /etc/sysctl.conf
# echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
# sysctl -p

# Test Docker Installation
docker run hello-world

echo "Docker installation and setup, along with security configurations, completed successfully."
