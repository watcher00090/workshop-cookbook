#!/bin/bash
{

hostnamectl set-hostname ${hostname}

# set up multiple ssh public keys for both ubuntu and root - allowing ssh to root account which is disabled in authorized_keys by AWS by default
mkdir -p /home/ubuntu/.ssh /root/.ssh/

if [ -f /home/ubuntu/.ssh/authorized_keys ]; then rm /home/ubuntu/.ssh/authorized_keys; fi
if [ -f /root/.ssh/authorized_keys ]; then rm /root/.ssh/authorized_keys; fi

# enable passwordless sudo for 'ubuntu'
echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/ubuntu-user

# adjust sshd_config to allow root ssh login
sed -i '/^[[:space:]]*PermitRootLogin/d' /etc/ssh/sshd_config && echo 'PermitRootLogin prohibit-password' | tee -a /etc/ssh/sshd_config

%{for ssh_public_key in ssh_public_keys~}
    echo '${lookup(ssh_public_key, "key_file", "__missing__") == "__missing__" ? trimspace(lookup(ssh_public_key, "key_data")) : trimspace(file(lookup(ssh_public_key, "key_file")))}' >> /home/ubuntu/.ssh/authorized_keys
    echo '${lookup(ssh_public_key, "key_file", "__missing__") == "__missing__" ? trimspace(lookup(ssh_public_key, "key_data")) : trimspace(file(lookup(ssh_public_key, "key_file")))}' >> /root/.ssh/authorized_keys
%{endfor~}

chown -R ubuntu:ubuntu /home/ubuntu/.ssh/

systemctl restart sshd

apt-get -qy update
apt-get -qy install \
%{for install_package in install_packages~}
    ${install_package} \
%{endfor~}

} >> /root/startup_script_log.txt 2>&1
