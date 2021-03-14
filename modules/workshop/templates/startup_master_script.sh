#!/bin/bash
{

export K3S_KUBECONFIG_MODE="644"
export INSTALL_K3S_EXEC=" --no-deploy servicelb --no-deploy traefik --token ${k3s_cluster_token} --cluster-cidr \"${pod_network_cidr}\" --node-name \"${node_name}\""

# create the cluster with k3s
curl -sfL https://get.k3s.io | sh -

# put the kubeconfig in ~/.kube
mkdir -p /home/ubuntu/.kube /root/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config # enable kubectl on the node
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# prepare kube config for download
#sudo kubectl --kubeconfig /home/ubuntu/admin.conf config set-cluster kubernetes --server https://INSERT_IP_ADDRESS_HERE:6443

} >> /root/startup_script_log.txt 2>&1