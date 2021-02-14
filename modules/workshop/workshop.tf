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
resource "aws_eip" "master" {
  vpc  = true
  tags = local.tags
}

resource "aws_eip_association" "master" {
  allocation_id = aws_eip.master.id
  instance_id   = aws_instance.master.id
}

#------------------------------------------------------------------------------#
# Bootstrap token for kubeadm
#------------------------------------------------------------------------------#

# Generate bootstrap token
# See https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

locals {
  token = "${random_string.token_id.result}.${random_string.token_secret.result}"
}

resource "tls_private_key" "internode_ssh" {
  algorithm   = "RSA"
  rsa_bits = "2048"
}

resource "aws_instance" "master" {
  ami           = var.ami
  instance_type = var.instance_type
  #availability_zone = "us-east-1a"
  subnet_id     = aws_subnet.mayalearning.id
  key_name = var.aws_public_key_name
  vpc_security_group_ids = [
    aws_security_group.allow_access.id
  ]
  root_block_device {
    volume_size = var.aws_instance_root_size_gb
  }
  #tags        = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-master-${format("%d", var.module_pass)}" })
  #volume_tags = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-master-${format("%d", var.module_pass)}" })
  tags        = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-${var.module_pass}-master" })
  volume_tags = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-${var.module_pass}-master" })

  connection {
    host = self.public_ip
    user = "ubuntu"
    private_key = file("id_rsa")
  }
  
  provisioner "file" {
    content = templatefile("${path.module}/templates/master_ssh.sh", {
      key : trimspace(tls_private_key.internode_ssh.public_key_openssh),
      private_key : trimspace(tls_private_key.internode_ssh.private_key_pem)
    })
    destination = "/home/ubuntu/master_ssh.sh"
  }
  
  
  provisioner "file" {
    content = templatefile("${path.module}/templates/machine-bootstrap.sh", {
      docker_version : var.docker_version,
      hostname : "${var.cluster_name}-${var.module_pass}-master",
      install_packages : var.install_packages,
      kubernetes_version : var.kubernetes_version,
      ssh_public_keys : var.ssh_public_keys,
      user : "ubuntu",
    })
    destination = "/home/ubuntu/machine-bootstrap.sh"
  }
  
  provisioner "file" {
    content = templatefile("${path.module}/templates/k8_master.sh", {
      token : "${local.token}",
      ip_address : "${aws_eip.master.public_ip}",
      flannel_cidr : "${local.flannel_cidr}",
      master_node_hostname : "${var.cluster_name}-${var.module_pass}-master",
    })
    destination = "/home/ubuntu/k8_master.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/ide_setup.sh", {
      workshop_url : "${var.workshop_url}"
    })
    destination = "/home/ubuntu/ide_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x /home/ubuntu/master_ssh.sh /home/ubuntu/k8_master.sh /home/ubuntu/ide_setup.sh",
      "sudo chmod 777 /home/ubuntu/machine-bootstrap.sh",
      "sudo chown root:root /home/ubuntu/machine-bootstrap.sh",
      "sudo su - root -c \"/home/ubuntu/machine-bootstrap.sh\"",
#      "/home/ubuntu/machine-bootstrap.sh",
      "/home/ubuntu/k8_master.sh",
      "/home/ubuntu/master_ssh.sh",
      "/home/ubuntu/ide_setup.sh",
    ]
  }
}

resource "null_resource" "start_theia_ide_server" {
  depends_on = [aws_instance.master, aws_eip.master, aws_eip_association.master]
  provisioner "local-exec" {
    command = "ssh -i id_rsa -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_eip.master.public_ip} 'cd /home/ubuntu/ide && ((nohup yarn start /home/ubuntu/workshop --hostname 0.0.0.0 --port 3000 < /dev/null > std.out 2> std.err) & echo Theia IDE started.....)'"
  }
}

resource "aws_instance" "worker" {
  depends_on = [aws_instance.master, aws_eip_association.master]
  ami = var.ami
  instance_type = var.instance_type
  #availability_zone = "us-east-1a"
  key_name = var.aws_public_key_name
  security_groups = [aws_security_group.allow_access.id]
  count = 2
tags = {
    #Name = "mayalearning-${format("%d", count.index)}"
    Name = "${var.cluster_name}-${var.module_pass}-worker-${count.index}"
  }
subnet_id = aws_subnet.mayalearning.id

  connection {
    host = self.public_ip
    user = "ubuntu"
    private_key = file("id_rsa")
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/worker_ssh.sh", {
      key : trimspace(tls_private_key.internode_ssh.public_key_openssh),
    })
    destination = "/home/ubuntu/worker_ssh.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/machine-bootstrap.sh", {
      docker_version : var.docker_version,
      hostname : "${var.cluster_name}-${var.module_pass}-worker-${count.index}",
      install_packages : var.install_packages,
      kubernetes_version : var.kubernetes_version,
      ssh_public_keys : var.ssh_public_keys,
      user : "ubuntu",
    })
    destination = "/home/ubuntu/machine-bootstrap.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/k8_worker.sh", {
      ip_address : "${aws_instance.master.private_ip}",
      token : "${local.token}",
#      clustername : "${var.cluster_name}",
      worker_node_hostname: "${var.cluster_name}-${var.module_pass}-worker-${count.index}"
      count_index : "${count.index}",
    })
    destination = "/home/ubuntu/k8_worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "set -xve",
      "chmod +x /home/ubuntu/k8_worker.sh /home/ubuntu/worker_ssh.sh /home/ubuntu/machine-bootstrap.sh",
#      "/home/ubuntu/machine-bootstrap.sh",
      "sudo chmod 777 /home/ubuntu/machine-bootstrap.sh",
      "sudo chown root:root /home/ubuntu/machine-bootstrap.sh",
      "sudo su - root -c \"/home/ubuntu/machine-bootstrap.sh\"",
      "/home/ubuntu/k8_worker.sh",
      "/home/ubuntu/worker_ssh.sh",
    ]
  }

}

resource "null_resource" "ssh_config" {
  depends_on = [aws_instance.worker]
  count = length(aws_instance.worker)
  connection {
    host = aws_eip.master.public_ip
    private_key = file("id_rsa")
    user = "ubuntu"
  }
  provisioner "remote-exec" {
    inline = [
      <<-EOF
        sudo echo 'Host worker${count.index}
          HostName ${aws_instance.worker[count.index].private_ip}
          User ubuntu
          Port 22
          IdentityFile ~/.ssh/internode_ssh'\
        >> /home/ubuntu/.ssh/config
        sudo chmod 600 /home/ubuntu/.ssh/config
        sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/config
        touch /home/ubuntu/done
      EOF
    ]
  }
}

/*
resource "null_resource" "wait_for_bootstrap_to_finish" {
  provisioner "local-exec" {
    command = <<-EOF
    alias ssh='ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    while true; do
      sleep 2
      ! ssh ubuntu@${aws_eip.master.public_ip} [[ -f /home/ubuntu/done ]] >/dev/null && continue
      %{for worker_public_ip in aws_instance.worker[*].public_ip~}
      ! ssh ubuntu@${worker_public_ip} [[ -f /home/ubuntu/done ]] >/dev/null && continue
      %{endfor~}
      break
    done
    EOF
  }
  triggers = {
    instance_ids = join(",", concat([aws_instance.master.id], aws_instance.worker[*].id))
  }
}*/

resource "null_resource" "flannel" {
  # well ... FIXME?
  # I like to have flannel removable/upgradeable via TF, but stuff required to SSH to the instance for destroy is destroyed before flannel :-/
  depends_on = [aws_eip_association.master, aws_instance.worker, aws_instance.master, aws_internet_gateway.mayalearning-env-gw, aws_route_table.route-table-mayalearning, aws_route_table_association.subnet-association]
  triggers = {
    host            = aws_eip.master.public_ip
    flannel_version = var.flannel_version
  }
  connection {
    host = self.triggers.host
    user = "ubuntu"
    private_key = file("id_rsa")
  }

  // NOTE: admin.conf is copied to ubuntu's home by kubeadm module
  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f \"https://raw.githubusercontent.com/coreos/flannel/v${self.triggers.flannel_version}/Documentation/kube-flannel.yml\""
    ]
  }

  # FIXME: deleting flannel's yaml isn't enough to undeploy it completely (e.g. /etc/cni/net.d/*, ...)
  # provisioner "remote-exec" {
  #  when = destroy
  #  inline = [
  #    "kubectl delete -f \"https://raw.githubusercontent.com/coreos/flannel/v${self.triggers.flannel_version}/Documentation/kube-flannel.yml\""
  #  ]
  #}
}