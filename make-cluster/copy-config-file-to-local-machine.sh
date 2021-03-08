#!/bin/bash

scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${MASTER_PUBLIC_IP}:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i "s/127\.0\.0\.1/${MASTER_PUBLIC_IP}/g" ~/.kube/config
sed -i "s/${MASTER_PRIVATE_IP}/${MASTER_PUBLIC_IP}/g" ~/.kube/config