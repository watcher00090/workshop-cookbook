#!/bin/bash
echo '${key}' > "/home/ubuntu/.ssh/internode_ssh.pub"
chmod 644 "/home/ubuntu/.ssh/internode_ssh.pub"
sudo cat '/home/ubuntu/.ssh/internode_ssh.pub' >> /home/ubuntu/.ssh/authorized_keys
set -e