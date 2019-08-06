#!/bin/bash -ex

# Add ubuntu user
# useradd -m -d /home/ubuntu -s /bin/bash ubuntu
# mkdir -p /home/ubuntu/.ssh
# cp /tmp/generated/id_rsa.pub /home/ubuntu/.ssh/authorized_keys
# chmod 600 /home/ubuntu/.ssh/authorized_keys
# chmod 700 /home/ubuntu/.ssh
# chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Disable default cloud-init config
echo > /var/lib/cloud/seed/nocloud-net/meta-data <<-EOM
instance_id: cloud-image
EOM
echo > /var/lib/cloud/seed/nocloud-net/user-data <<-EOM
#cloud-config
EOM
