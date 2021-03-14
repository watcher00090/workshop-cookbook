#!/bin/bash 

# this key lets workers ssh into the root account of master, which is why I'm hiding it
mkdir -p ${path_to_servicekey_files}
echo '${key}' >> ${path_to_servicekey_files}/servicekey.pub
ssh-keygen -l -f ${path_to_servicekey_files}/servicekey.pub >> /root/.ssh/known_hosts
echo '${private_key}' > "${path_to_servicekey_files}/servicekey"
chmod 600 "${path_to_servicekey_files}/servicekey"
touch /root/finished_adding_servicekey_worker


