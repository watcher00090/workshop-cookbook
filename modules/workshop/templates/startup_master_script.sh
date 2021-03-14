#!/bin/bash
{

export K3S_KUBECONFIG_MODE="644"
export INSTALL_K3S_EXEC=" --no-deploy servicelb --no-deploy traefik --token ${k3s_cluster_token} --cluster-cidr \"${pod_network_cidr}\" --node-name \"${node_name}\""

# create the cluster with k3s
curl -sfL https://get.k3s.io | sh -

} >> /root/startup_script_log.txt 2>&1