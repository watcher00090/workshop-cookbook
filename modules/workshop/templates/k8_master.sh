#!/bin/bash
sudo systemctl unmask docker
sudo systemctl start docker
# Run kubeadm
sudo kubeadm init \
--token ${token} \
--token-ttl 1440m \
--apiserver-cert-extra-sans ${ip_address} \
--pod-network-cidr ${flannel_cidr} \
--node-name ${master_node_hostname}
sudo systemctl enable kubelet
# Prepare kubeconfig file for download to local machine
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config # enable kubectl on the node
sudo mkdir /root/.kube
sudo cp /etc/kubernetes/admin.conf /root/.kube/config
chown ubuntu:ubuntu /home/ubuntu/admin.conf /home/ubuntu/.kube/config
# prepare kube config for download
sudo kubectl --kubeconfig /home/ubuntu/admin.conf config set-cluster kubernetes --server https://${ip_address}:6443
# Indicate completion of bootstrapping on this node
touch /home/ubuntu/done