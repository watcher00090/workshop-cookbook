output "instance_ips" {  
    value = aws_eip.master.*.public_ip
}