
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
 # default = "ami-0996d3051b72b5b2c" (old ami, not sure where it comes from....)


  # use this Ubuntu 20.04 LTS amd64 image: ami-08962a4068733a2b6 instead ? 

  default = "ami-08962a4068733a2b6"
}

variable "instance_type" {}

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
    "build-essential",
    "python3-pip",
    "curl"
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

variable "flannel_version" {
  type        = string
  description = "Version of flannel CNI to deploy to the cluster."
}

variable "module_pass" {
  description = "number of times the module has run"
}

variable "path_to_servicekey_files" {
  type = string
  default = "/var/lib/servicekey"
}