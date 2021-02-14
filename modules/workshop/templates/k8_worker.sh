#!/bin/bash
sudo systemctl unmask docker
sudo systemctl enable docker
sudo systemctl enable kubelet

# sudo systemctl start docker
# Run kubeadm
sudo kubeadm join ${ip_address}:6443 \
--token ${token} \
--discovery-token-unsafe-skip-ca-verification \
--node-name ${worker_node_hostname}


# sudo systemctl enable docker kubelet
# Indicate completion of bootstrapping on this node
touch /home/ubuntu/done