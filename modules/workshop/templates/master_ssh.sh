#!/bin/bash
echo ${key} >> /home/ubuntu/.ssh/internode_ssh.pub
chown ubuntu:ubuntu /home/ubuntu/.ssh/internode_ssh.pub
ssh-keygen -l -f /home/ubuntu/.ssh/internode_ssh.pub >> known_hosts
echo ${private_key} > "/home/ubuntu/.ssh/internode_ssh"
chown ubuntu:ubuntu /home/ubuntu/.ssh/internode_ssh
chmod 600 "/home/ubuntu/.ssh/internode_ssh"
set -e