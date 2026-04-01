#!/bin/bash

CURRENT_HOSTNAME=$(hostname -s)
NEW_HOSTNAME="${CURRENT_HOSTNAME}.example.com"

hostnamectl set-hostname $NEW_HOSTNAME

IP_ADDR=$(hostname -I | awk '{print $1}')

echo "$IP_ADDR $NEW_HOSTNAME $CURRENT_HOSTNAME" >> /etc/hosts

sudo useradd admin || true
echo "admin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin
echo "admin:Redhat@123" | chpasswd

subscription-manager register --username=$1 --password=$2 --auto-attach

subscription-manager repos --enable=rhel-10-for-x86_64-baseos-rpms
subscription-manager repos --enable=rhel-10-for-x86_64-appstream-rpms

dnf install -y ansible-core wget git-core rsync

su - admin -c "cd /home/admin && wget $3 -O aap.tar.gz"
su - admin -c "cd /home/admin && tar -xvzf aap.tar.gz"

INVENTORY_PATH="/home/admin/ansible-automation-platform-containerized-setup-2.6-6/inventory"

sed -i "s/RHEL-10.example.com/$NEW_HOSTNAME/g" $INVENTORY_PATH

grep -q "^automationcontroller_hostnames=" $INVENTORY_PATH && \
sed -i "s/^automationcontroller_hostnames=.*/automationcontroller_hostnames=$NEW_HOSTNAME/" $INVENTORY_PATH || \
echo "automationcontroller_hostnames=$NEW_HOSTNAME" >> $INVENTORY_PATH

echo "automationhub_hostnames=$NEW_HOSTNAME" >> $INVENTORY_PATH
echo "automationgateway_hostnames=$NEW_HOSTNAME" >> $INVENTORY_PATH
echo "automationeda_hostnames=$NEW_HOSTNAME" >> $INVENTORY_PATH

su - admin -c "cd /home/admin/ansible-automation-platform-containerized-setup-2.6-6 && ansible-playbook -i inventory ansible.containerized_installer.install"
