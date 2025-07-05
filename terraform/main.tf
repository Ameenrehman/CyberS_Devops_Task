provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source       = "./modules/eks"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.subnet_ids
  cluster_name = var.cluster_name
}