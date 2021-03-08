module "make-cluster" {
    source = "./make-cluster"
}

module "make-pods" {
    depends_on = [module.make-cluster]
    source = "./make-pods"
} 