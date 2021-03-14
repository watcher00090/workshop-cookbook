#!/bin/bash
{

# check that the cluster has come up
while true; do
    sleep 2
    ! curl https://${control_plane_address}:6443/api --insecure >/dev/null && continue # TODO IMPROVE THIS, FOR INSTNACE TRY TO GET THE NAME OF THE KUBERNETES SERVICE AND TEST THAT IT'S service/kubernetes OR SOMETHING LIKE THAT
    break
done

export K3S_KUBECONFIG_MODE="644"
export K3S_URL="https://${control_plane_address}:6443"
export K3S_TOKEN=${k3s_cluster_token}
export INSTALL_K3S_EXEC="--node-name ${worker_node_hostname}"

# join the cluster
curl -sfL https://get.k3s.io | sh -

} > join_worker_to_cluster_log.txt 2>&1