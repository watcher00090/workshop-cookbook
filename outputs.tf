output "instance_info" {  
    value = module.workshop.*.instance_ips
}