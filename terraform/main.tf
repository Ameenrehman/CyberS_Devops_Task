provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
  cluster_name = var.cluster_name
}

module "eks" {
  source       = "./modules/eks"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.subnet_ids
  cluster_name = var.cluster_name
  github_actions_runner_iam_role_arn = "arn:aws:iam::593793064016:user/Ammen"

}