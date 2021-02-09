module "workshop" {
  source = "./modules/workshop"
  count = var.cluster_count
  cluster_name = "learning-cluster"
  tags = var.tags
  aws_instance_root_size_gb = var.aws_instance_root_size_gb
}
