module "setup" {
  source = "./modules/setup"
}

module "workshop" {
  source = "./modules/workshop"
  count = var.cluster_count
  cluster_name = "learning-cluster"
  tags = var.tags
  aws_instance_root_size_gb = var.aws_instance_root_size_gb
  flannel_version = var.flannel_version
  module_pass = count.index
  aws_public_key_name = module.setup.aws_public_key_name

  depends_on = [module.setup]
}