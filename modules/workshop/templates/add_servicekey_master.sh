#!/bin/bash
echo '${key}' > "/root/.ssh/servicekey.pub"
chmod 644 "/root/.ssh/servicekey.pub"
sudo cat '/root/.ssh/servicekey.pub' >> /root/.ssh/authorized_keys
touch /root/finished_adding_servicekey_master