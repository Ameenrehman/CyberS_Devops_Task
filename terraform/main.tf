
/* module "eks" {
  source       = "./modules/eks"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.subnet_ids
  cluster_name = var.cluster_name
  github_actions_runner_iam_role_arn = "arn:aws:iam::593793064016:user/Ammen"

} */


provider "aws" {
  region = local.region
}

locals {
  name   = "ascode-cluster"
  region = "us-east-1"

  vpc_cidr = "10.123.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]
  #private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]
  intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"]

  tags = {
    Example = local.name
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  #private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    #ami_type       = "AL2_x86_64"
    #instance_types = ["m5.large"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    ascode-cluster-wg = {
      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      tags = {
        ExtraTag = "helloworld"
      }
    }
  }
  
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.eks.eks_managed_node_group_iam_role_arns["ascode-cluster-wg"] # Node group role
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn # <--- REPLACE WITH YOUR ACTUAL IAM USER ARN
      username =  module.eks_admins_iam_role.iam_role_name
      groups   = ["system:masters"] # Grants cluster-admin permissions
    }
  ]
  tags = local.tags
}