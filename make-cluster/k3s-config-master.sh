#!/bin/bash

export K3S_KUBECONFIG_MODE=\"644\" && export INSTALL_K3S_EXEC=\" --no-deploy servicelb --no-deploy traefik --bind-address ${MASTER_PRIVATE_IP} --tls-san ${MASTER_PUBLIC_IP}\" && sudo apt-get update -y && sudo apt-get install -y curl && curl -sfL https://get.k3s.io | sh -