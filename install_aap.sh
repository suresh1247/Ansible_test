#!/bin/bash

sudo useradd admin || true
echo "admin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin
echo "admin:Redhat@123" | chpasswd

subscription-manager register --username=$1 --password=$2 --auto-attach

subscription-manager repos --enable=rhel-10-for-x86_64-baseos-rpms
subscription-manager repos --enable=rhel-10-for-x86_64-appstream-rpms

dnf install -y ansible-core wget git-core rsync

su - admin -c "cd /home/admin && wget $3 -O aap.tar.gz"
su - admin -c "cd /home/admin && tar -xvzf aap.tar.gz"

su - admin -c "cd /home/admin/ansible-automation-platform-containerized-setup-2.6-6 && ansible-playbook -i inventory ansible.containerized_installer.install"
