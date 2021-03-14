output "instance_info" {  
    value = [for i in range(0,length(module.workshop)): module.workshop[i].master_ip]
}

output "instance_ips" {
    value = [for i in range(0,length(module.workshop)): 
        merge({"cluster-${i}-master-public-ip" : module.workshop[i].master_ip},
                {for j in range(0,2): "cluster-${i}-worker-${j}-public-ip" => module.workshop[i].worker_ips[j]}
            )
        ]
}