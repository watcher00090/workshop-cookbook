locals {
  tags         = merge(var.tags, { "terraform-kubeadm:cluster" = var.cluster_name, "Name" = "${var.cluster_name}-${var.module_pass}-master" })
  flannel_cidr = "10.244.0.0/16" # hardcoded in flannel, do not change
}

resource "aws_vpc" "mayalearning" {
  cidr_block       = var.aws_vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "mayalearning-vpc-${var.module_pass}"
  }
}

resource "aws_subnet" "mayalearning" {
  vpc_id     = aws_vpc.mayalearning.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "mayalearning-subnet-${var.module_pass}"
  }
}

resource "aws_security_group" "allow_access" {
  name        = "security-group-allow-access-${var.module_pass}"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.mayalearning.id

  ingress {
    description = "SSH from Anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  
  ingress {
    description = "Theia-ide"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "intersubnet communication"
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-group-allow-access-${var.module_pass}"
  }
}

resource "aws_internet_gateway" "mayalearning-env-gw" {
  vpc_id = aws_vpc.mayalearning.id
tags = {
    Name = "mayalearning-env-gw-${var.module_pass}"
  }
}

resource "aws_route_table" "route-table-mayalearning" {
  vpc_id = aws_vpc.mayalearning.id
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mayalearning-env-gw.id
  }
tags = {
    Name = "mayalearning-route-table-${var.module_pass}"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.mayalearning.id
  route_table_id = aws_route_table.route-table-mayalearning.id 
}

#------------------------------------------------------------------------------#
# Elastic IP for master node
#------------------------------------------------------------------------------#

# EIP for master node because it must know its public IP during initialisation
#resource "aws_eip" "master" {
#  vpc  = true
#  tags = local.tags
#}

#resource "aws_eip_association" "master" {
#  allocation_id = aws_eip.master.id
#  instance_id   = aws_instance.master.id
#}

#------------------------------------------------------------------------------#
# Bootstrap token for kubeadm
#------------------------------------------------------------------------------#

# Generate bootstrap token
# See https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/
/*
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}
*/

/*
resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}
*/

/*
locals {
  token = "${random_string.token_id.result}.${random_string.token_secret.result}"
}
*/

resource "tls_private_key" "internode_ssh" {
  algorithm   = "RSA"
  rsa_bits = "2048"
}

resource "tls_private_key" "servicekey" {
  algorithm   = "RSA"
  rsa_bits = "2048"
}

resource "random_string" "k3s_cluster_token" {
  length = 16
  special = false
  upper = false
}

resource "aws_instance" "master" {
  ami           = var.ami
  instance_type = var.instance_type
  #availability_zone = "us-east-1a"
  subnet_id     = aws_subnet.mayalearning.id
#  key_name = var.aws_public_key_name
  vpc_security_group_ids = [
    aws_security_group.allow_access.id
  ]
  root_block_device {
    volume_size = var.aws_instance_root_size_gb
  }
  tags        = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-${var.module_pass}-master" })
  volume_tags = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-${var.module_pass}-master" })

  user_data = <<-EOF
    ${templatefile("${path.module}/templates/startup_machine_bootstrap.sh",{
      hostname : "${var.cluster_name}-${var.module_pass}-master",
      install_packages : var.install_packages,
      ssh_public_keys : var.ssh_public_keys,
    })}

    ${templatefile("${path.module}/templates/startup_master_script.sh",{
      k3s_cluster_token = random_string.k3s_cluster_token.result,
      pod_network_cidr = local.flannel_cidr,
      node_name = "${var.cluster_name}-${var.module_pass}-master",
    })}

    ${templatefile("${path.module}/templates/master_ssh.sh",{
      key : trimspace(tls_private_key.internode_ssh.public_key_openssh),
      private_key : trimspace(tls_private_key.internode_ssh.private_key_pem)
    })}

    ${templatefile("${path.module}/templates/add_servicekey_master.sh",{
      key : trimspace(tls_private_key.servicekey.public_key_openssh),
    })}

    touch /root/done
  EOF
}

resource "null_resource" "start_theia_ide_server" {
  depends_on = [aws_instance.master, null_resource.wait_for_bootstrap_to_finish]
  connection {
    host = aws_instance.master.public_ip
    user = "ubuntu"
    private_key = file("id_rsa")
    agent = false
  }
  /*
  provisioner "file" {
    content = templatefile("${path.module}/templates/ide_setup_and_start.sh", {
      workshop_url : "${var.workshop_url}"
    })
    destination = "/home/ubuntu/ide_setup_and_start.sh"
  }
  provisioner "file" {
    content = templatefile("${path.module}/templates/ide_setup_and_start_helper.sh", {
      workshop_url : "${var.workshop_url}"
    })
    destination = "/home/ubuntu/ide_setup_and_start_helper.sh"
  }
  */
   # provisioner "remote-exec" {
 #   inline = ["chmod +x /home/ubuntu/ide_setup_and_start.sh /home/ubuntu/ide_setup_and_start_helper.sh && (nohup /home/ubuntu/ide_setup_and_start.sh &>/dev/null &)"]
 # }
  provisioner "file" {
    content = templatefile("${path.module}/templates/setup-and-start-theia.sh", {
      workshop_url : "${var.workshop_url}"
    })
    destination = "/home/ubuntu/setup-and-start-theia.sh"
  }
  provisioner "remote-exec" {
    inline = ["chmod +x /home/ubuntu/setup-and-start-theia.sh",
              "nohup /home/ubuntu/setup-and-start-theia.sh </dev/null >/home/ubuntu/theia_setup_and_start_log.txt 2>&1 &",
              "sleep 3",
              "sudo mv /home/ubuntu/theia_setup_and_start_log.txt /root/theia_setup_and_start_log.txt",
              "sudo chown root:root /root/theia_setup_and_start_log.txt"]
  }
}

#resource "null_resource" "start_theia_ide_server" {
#  depends_on = [aws_instance.master, aws_eip.master, aws_eip_association.master]
#  provisioner "local-exec" {
#    command = "ssh -i id_rsa -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_eip.master.public_ip} 'cd /home/ubuntu/ide && ((nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 < /dev/null > std.out 2> std.err) & echo Theia IDE started.....)'"
#  }
#}

resource "aws_instance" "worker" {
  ami = var.ami
  instance_type = var.instance_type
  #availability_zone = "us-east-1a"
#  key_name = var.aws_public_key_name
  security_groups = [aws_security_group.allow_access.id]
  count = 2
  tags = {
    Name = "${var.cluster_name}-${var.module_pass}-worker-${count.index}"
  }
  subnet_id = aws_subnet.mayalearning.id

  user_data = <<-EOF
    ${templatefile("${path.module}/templates/startup_machine_bootstrap.sh",{
      hostname : "${var.cluster_name}-${var.module_pass}-worker-${count.index}",
      install_packages : var.install_packages,
      ssh_public_keys : var.ssh_public_keys,
    })}

    ${templatefile("${path.module}/templates/worker_ssh.sh",{
      key : trimspace(tls_private_key.internode_ssh.public_key_openssh),
    })}

    ${templatefile("${path.module}/templates/add_servicekey_worker.sh",{
      key : trimspace(tls_private_key.servicekey.public_key_openssh),
      private_key : trimspace(tls_private_key.servicekey.private_key_pem),
      path_to_servicekey_files : var.path_to_servicekey_files
    })}

    touch /root/done
  EOF
}

/*
resource "null_resource" "generate_client_certificates" {
  depends_on = [null_resource.wait_for_bootstrap_to_finish]
  count = 2
  connection {
    host = aws_instance.worker[count.index].public_ip
    user = "root"
    private_key = file("id_rsa")
    agent = false
  }  
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/tls/",
      "scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.path_to_servicekey_files}/servicekey root@${aws_instance.master.public_ip}:/var/lib/rancher/k3s/server/tls/client-ca.crt ~/tls/",
      "scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.path_to_servicekey_files}/servicekey root@${aws_instance.master.public_ip}:/var/lib/rancher/k3s/server/tls/client-ca.key ~/tls/",
      "openssl genrsa -out ~/tls/k8s-user.key 4096",
      "openssl req -new -key ~/tls/k8s-user.key -out ~/tls/k8s-user.csr -subj \"/CN=user@default/O=admins\"",
      "openssl x509 -req -in ~/tls/k8s-user.csr -CA ~/tls/client-ca.crt -CAkey ~/tls/client-ca.key -CAcreateserial -out ~/tls/k8s-user.crt -days 10000",
      "sudo cp ~/tls/k8s-user.crt /usr/local/share/ca-certificates/kubernetes.crt",
      "sudo update-ca-certificates",
    ]
  }
}
*/

resource "null_resource" "join_workers_to_cluster" {
  depends_on = [aws_instance.master, aws_instance.worker, null_resource.wait_for_bootstrap_to_finish]
  count = 2
  connection {
    host = aws_instance.worker[count.index].public_ip
    user = "root"
    private_key = file("id_rsa")
    agent = false
  }  
  provisioner "file" {
    content = templatefile("${path.module}/templates/join_worker_to_cluster.sh", {
      control_plane_address : "${aws_instance.master.private_ip}",
      worker_node_hostname: "${var.cluster_name}-${var.module_pass}-worker-${count.index}",
      k3s_cluster_token: random_string.k3s_cluster_token.result,
    })
    destination = "/root/join_worker_to_cluster.sh"
  }
 # provisioner "remote-exec" {
 #   inline = ["sudo su root -c 'mv /home/ubuntu/join_worker_to_cluster.sh /root/join_worker_to_cluster.sh && chmod +x /root/join_worker_to_cluster.sh && (nohup /root/join_worker_to_cluster.sh &)'"]
 #   inline = ["chmod +x /root/join_worker_to_cluster.sh",
 #             "/root/join_worker_to_cluster.sh",
 #             "touch /root/remote-exec-completed"]
  provisioner "remote-exec" {
    inline = ["chmod +x /root/join_worker_to_cluster.sh",
              "nohup /root/join_worker_to_cluster.sh < /dev/null >/root/join_worker_to_cluster_log.txt 2>&1 &",
              "sleep 3"
    ]
  }
}

resource "null_resource" "ssh_config" {
  depends_on = [aws_instance.worker, null_resource.wait_for_bootstrap_to_finish]
  count = length(aws_instance.worker)
  connection {
    #host = aws_eip.master.public_ip
    host = aws_instance.master.public_ip
    private_key = file("id_rsa")
    user = "ubuntu"
    agent = false
  }
  provisioner "remote-exec" {
    inline = [
      <<-EOF
        sudo echo 'Host worker${count.index}
          HostName ${aws_instance.worker[count.index].private_ip}
          User ubuntu
          Port 22
          IdentityFile /home/ubuntu/.ssh/internode_ssh'\
        >> /home/ubuntu/.ssh/config
        sudo chmod 600 /home/ubuntu/.ssh/config
        sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/config
        touch /home/ubuntu/done
      EOF
    ]
  }
}

#locals {
#  check_api_server_available_command = <<-EOF
#    while true; do
#      sleep 2
#      ! curl https://${aws_instance.master.private_ip}:6443/api --insecure >/dev/null && continue
#      break
#    done
#  EOF
#}

resource "null_resource" "wait_for_bootstrap_to_finish" {
  depends_on = [aws_instance.master, aws_instance.worker]
  provisioner "local-exec" {  # check that configuring ssh on the nodes has completed
    command = <<-EOF
    alias ssh='ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    while true; do
      sleep 2
      ! ssh -i ./id_rsa root@${aws_instance.master.public_ip} [[ -f /root/done ]] >/dev/null && continue
      %{for worker_public_ip in aws_instance.worker[*].public_ip~}
      ! ssh -i ./id_rsa root@${worker_public_ip} [[ -f /root/done ]] >/dev/null && continue
      %{endfor~}
      break
    done
    EOF
  }
}