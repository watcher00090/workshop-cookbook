
variable "cluster_name" {
  type        = string
  description = "Name of the cluster. Used as a part of AWS names and tags of various cluster components."
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to assign to the created AWS resources. These tags will be assigned in addition to the default tags. The default tags include \"terraform-kubeadm:cluster\" which is assigned to all resources and whose value is the cluster name, and \"terraform-kubeadm:node\" which is assigned to the EC2 instances and whose value is the name of the Kubernetes node that this EC2 corresponds to."
  default     = {}
}

variable "ami" {
  type        = string
  description = "A set of tags to assign to the created AWS resources. These tags will be assigned in addition to the default tags. The default tags include \"terraform-kubeadm:cluster\" which is assigned to all resources and whose value is the cluster name, and \"terraform-kubeadm:node\" which is assigned to the EC2 instances and whose value is the name of the Kubernetes node that this EC2 corresponds to."
  default     = "ami-0c3aa5b042768797c"
}

variable "instance_type" {
  type        = string
  description = "A set of tags to assign to the created AWS resources. These tags will be assigned in addition to the default tags. The default tags include \"terraform-kubeadm:cluster\" which is assigned to all resources and whose value is the cluster name, and \"terraform-kubeadm:node\" which is assigned to the EC2 instances and whose value is the name of the Kubernetes node that this EC2 corresponds to."
  default     = "t3.medium"
  //default = "m5ad.large"
//  default = "c5ad.xlarge"
//  default = "i3.large"
}

variable "aws_vpc_cidr_block" {
  type        = string
  description = "CIDR block to use for AWS VPC network addresses."
  default     = "10.0.0.0/16"
}

variable "aws_instance_root_size_gb" {}

variable "docker_version" {
  type        = string
  description = "Docker version to install."
  default     = "19.03"
}

variable "install_packages" {
  type        = list(string)
  description = "Additional deb packages to install during instance bootstrap."
  default = [
    "fio",
    "iotop",
    "nvme-cli",
    "strace",
    "sysstat",
    "tcpdump",
  ]
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to install."
  default     = "1.19.4"
}

variable "ssh_public_keys" {
  type        = map(map(string))
  description = "Map of maps of public ssh keys. See variables.tf for full example. Default is ~/.ssh/id_rsa.pub. Due to AWS limitations you **have** to have one key named 'key1' which is a RSA key."
  default = {
    "key1" = { "key_file" = "./id_rsa.pub" },
  }
}

variable "workshop_url" {
    type = string
    description = "github url of workshop"
    default = "https://github.com/mando222/WorkshopTemplate.git"
}