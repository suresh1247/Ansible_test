#!/bin/bash

set -e

RHSM_USER=$1
RHSM_PASS=$2
AAP_URL=$3

# ---------------------------
# STEP 1: Get current hostname
# ---------------------------
CURRENT_HOSTNAME=$(hostname -s)
NEW_HOSTNAME="${CURRENT_HOSTNAME}.example.com"

echo "Updating hostname to: $NEW_HOSTNAME"

# ---------------------------
# STEP 2: Set hostname
# ---------------------------
hostnamectl set-hostname $NEW_HOSTNAME

# ---------------------------
# STEP 3: Get IP address
# ---------------------------
IP_ADDR=$(hostname -I | awk '{print $1}')

# ---------------------------
# STEP 4: Update /etc/hosts
# ---------------------------
echo "$IP_ADDR $NEW_HOSTNAME $CURRENT_HOSTNAME" >> /etc/hosts

# ---------------------------
# STEP 5: Create admin user
# ---------------------------
useradd admin || true
echo "admin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin
echo "admin:Redhat@123" | chpasswd

# ---------------------------
# STEP 6: Register RHEL
# ---------------------------
subscription-manager register --username=$RHSM_USER --password=$RHSM_PASS
subscription-manager attach --auto

subscription-manager repos --enable=rhel-10-for-x86_64-baseos-rpms
subscription-manager repos --enable=rhel-10-for-x86_64-appstream-rpms

# ---------------------------
# STEP 7: Install dependencies
# ---------------------------
dnf install -y ansible-core wget git-core rsync

# ---------------------------
# STEP 8: Download AAP bundle
# ---------------------------
su - admin -c "cd /home/admin && wget $AAP_URL -O aap.tar.gz"

# ---------------------------
# STEP 9: Extract bundle
# ---------------------------
su - admin -c "cd /home/admin && tar -xvzf aap.tar.gz"

# ---------------------------
# STEP 10: Update inventory
# ---------------------------
INVENTORY_PATH="/home/admin/ansible-automation-platform-containerized-setup-2.6-6/inventory"

echo "Updating inventory with hostname: $NEW_HOSTNAME"

sed -i "s/RHEL-10.example.com/$NEW_HOSTNAME/g" $INVENTORY_PATH

# ---------------------------
# STEP 11: Run installer
# ---------------------------
su - admin -c "cd /home/admin/ansible-automation-platform-containerized-setup-2.6-6 && ansible-playbook -i inventory ansible.containerized_installer.install"
