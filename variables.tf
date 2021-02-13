
variable "cluster_count" {
  type        = number
  description = "Number of clusters to create"
  default     = 1
}

variable "tags" {
  type        = map(string)
  description = "A set of tags to assign to the created AWS resources. These tags will be assigned in addition to the default tags. The default tags include \"terraform-kubeadm:cluster\" which is assigned to all resources and whose value is the cluster name, and \"terraform-kubeadm:node\" which is assigned to the EC2 instances and whose value is the name of the Kubernetes node that this EC2 corresponds to."
  default     = {}
}

variable "aws_instance_root_size_gb" {
  type        = number
  default     = 8
  description = "Root block device size for AWS instances in GiB. Clean install (currently) uses a little over 4. Not recommended to use less than default."
}

variable "flannel_version" {
  type        = string
  description = "Version of flannel CNI to deploy to the cluster."
  default     = "0.13.0"
}