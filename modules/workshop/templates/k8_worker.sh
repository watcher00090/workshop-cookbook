#!/bin/bash
sudo systemctl unmask docker
sudo systemctl start docker
sudo systemctl start kubelet
# Run kubeadm
sudo kubeadm join ${ip_address}:6443 \
--token ${token} \
--discovery-token-unsafe-skip-ca-verification \
--node-name ${clustername}-worker-${count_index}
sudo systemctl enable docker kubelet
# Indicate completion of bootstrapping on this node
touch /home/ubuntu/done