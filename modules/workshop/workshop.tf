locals {
  tags         = merge(var.tags, { "terraform-kubeadm:cluster" = var.cluster_name, "Name" = var.cluster_name })
  flannel_cidr = "10.244.0.0/16" # hardcoded in flannel, do not change
}

resource "aws_vpc" "mayalearning" {
  cidr_block       = var.aws_vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "mayalearning"
  }
}

resource "aws_subnet" "mayalearning" {
  vpc_id     = aws_vpc.mayalearning.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "mayalearning"
  }
}

resource "aws_security_group" "allow_access" {
  name        = "allow_access"
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
    Name = "allow_access"
  }
}

resource "aws_internet_gateway" "mayalearning-env-gw" {
  vpc_id = aws_vpc.mayalearning.id
tags = {
    Name = "mayalearning-env-gw"
  }
}

resource "aws_route_table" "route-table-mayalearning" {
  vpc_id = aws_vpc.mayalearning.id
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mayalearning-env-gw.id
  }
tags = {
    Name = "mayalearning-route-table"
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
  subnet_id     = aws_subnet.mayalearning.id
  key_name = "MayaLearning"
  vpc_security_group_ids = [
    aws_security_group.allow_access.id
  ]
  root_block_device {
    volume_size = var.aws_instance_root_size_gb
  }
  tags        = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-master" })
  volume_tags = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-master" })
  user_data = <<-EOF
  #!/bin/bash
  echo '${trimspace(tls_private_key.internode_ssh.public_key_openssh)}' >> /home/ubuntu/.ssh/internode_ssh.pub
    chown ubuntu:ubuntu /home/ubuntu/.ssh/internode_ssh.pub
  ssh-keygen -l -f /home/ubuntu/.ssh/internode_ssh.pub >> known_hosts
  echo '${trimspace(tls_private_key.internode_ssh.private_key_pem)}' > "/home/ubuntu/.ssh/internode_ssh"
  chown ubuntu:ubuntu /home/ubuntu/.ssh/internode_ssh
  chmod 600 "/home/ubuntu/.ssh/internode_ssh"
  #chown root:root /home/ubuntu/.ssh/known_hosts
  set -e
  ${templatefile("${path.module}/templates/machine-bootstrap.sh", {
  docker_version : var.docker_version,
  hostname : "${var.cluster_name}-master",
  install_packages : var.install_packages,
  kubernetes_version : var.kubernetes_version,
  ssh_public_keys : var.ssh_public_keys,
  user : "ubuntu",
})}
  systemctl unmask docker
  systemctl start docker
  # Run kubeadm
  kubeadm init \
    --token "${local.token}" \
    --token-ttl 1440m \
    --apiserver-cert-extra-sans "${aws_eip.master.public_ip}" \
    --pod-network-cidr "${local.flannel_cidr}" \
    --node-name ${var.cluster_name}-master
  systemctl enable kubelet
  # Prepare kubeconfig file for download to local machine
  mkdir -p /home/ubuntu/.kube
  cp /etc/kubernetes/admin.conf /home/ubuntu
  cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config # enable kubectl on the node
  sudo mkdir /root/.kube
  sudo cp /etc/kubernetes/admin.conf /root/.kube/config
  chown ubuntu:ubuntu /home/ubuntu/admin.conf /home/ubuntu/.kube/config
  # prepare kube config for download
  kubectl --kubeconfig /home/ubuntu/admin.conf config set-cluster kubernetes --server https://${aws_eip.master.public_ip}:6443
  # Indicate completion of bootstrapping on this node
  touch /home/ubuntu/done
  docker pull theiaide/sadl
  docker run -it -p 3000:3000 -v "$(pwd):/home/project" theiaide/sadl
  
  EOF
}

//servers.tf
resource "aws_instance" "worker" {
  depends_on = [aws_instance.master]
  ami = var.ami
  instance_type = var.instance_type
  key_name = "MayaLearning"
  security_groups = [aws_security_group.allow_access.id]
  count = 2
tags = {
    Name = "mayalearning-${format("%d", count.index + 1)}"
  }
subnet_id = aws_subnet.mayalearning.id
  user_data = <<-EOF
  #!/bin/bash
  echo '${trimspace(tls_private_key.internode_ssh.public_key_openssh)}' > "/home/ubuntu/.ssh/internode_ssh.pub"
  chmod 644 "/home/ubuntu/.ssh/internode_ssh.pub"
  sudo cat '/home/ubuntu/.ssh/internode_ssh.pub' >> /home/ubuntu/.ssh/authorized_keys
  set -e
  ${templatefile("${path.module}/templates/machine-bootstrap.sh", {
  docker_version : var.docker_version,
  hostname : "${var.cluster_name}-worker-${count.index}",
  install_packages : var.install_packages,
  kubernetes_version : var.kubernetes_version,
  ssh_public_keys : var.ssh_public_keys,
  user : "ubuntu",
})}
  systemctl unmask docker
  systemctl start docker
  systemctl start kubelet
  # Run kubeadm
  kubeadm join ${aws_instance.master.private_ip}:6443 \
    --token ${local.token} \
    --discovery-token-unsafe-skip-ca-verification \
    --node-name ${var.cluster_name}-worker-${count.index}
  systemctl enable docker kubelet
  # Indicate completion of bootstrapping on this node
  touch /home/ubuntu/done
  EOF
}