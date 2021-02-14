#!/bin/bash
sudo systemctl unmask docker
sudo systemctl enable docker
sudo systemctl enable kubelet

# sudo systemctl start docker
# Run kubeadm
sudo kubeadm init \
--token ${token} \
--token-ttl 1440m \
--apiserver-cert-extra-sans ${ip_address} \
--pod-network-cidr ${flannel_cidr} \
--node-name ${master_node_hostname}
# Prepare kubeconfig file for download to local machine
sudo mkdir -p /home/ubuntu/.kube
sudo cp /etc/kubernetes/admin.conf /home/ubuntu
sudo cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config # enable kubectl on the node
sudo mkdir /root/.kube
sudo cp /etc/kubernetes/admin.conf /root/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/admin.conf /home/ubuntu/.kube/config
# prepare kube config for download
sudo kubectl --kubeconfig /home/ubuntu/admin.conf config set-cluster kubernetes --server https://${ip_address}:6443
# Indicate completion of bootstrapping on this node
touch /home/ubuntu/done