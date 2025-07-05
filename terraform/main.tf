
/* module "eks" {
  source       = "./modules/eks"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.subnet_ids
  cluster_name = var.cluster_name
  github_actions_runner_iam_role_arn = "arn:aws:iam::593793064016:user/Ammen"

} */



# Pin the AWS provider version for compatibility with modules
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Pin to a compatible major version
    }
  }
}

provider "aws" {
  region = local.region
}

# Configure the Kubernetes provider to connect to the EKS cluster
# This uses outputs from the EKS module to get the cluster endpoint and CA certificate.
# It also uses the aws_eks_cluster_auth data source to get a temporary authentication token.
data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
}

locals {
  name = "ascode-cluster"
  region = "us-east-1"

  vpc_cidr = "10.123.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]
  private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]
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

  azs              = local.azs
  private_subnets  = local.private_subnets
  public_subnets   = local.public_subnets
  intra_subnets    = local.intra_subnets
  map_public_ip_on_launch = true
  enable_nat_gateway = false
  single_nat_gateway = false # default
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true
  
  /* cluster_addons = {
    coredns = {
      most_recent = true
      # resolve_conflicts = "OVERWRITE" # <--- REMOVED THIS ARGUMENT
    }
    kube-proxy = {
      most_recent = true
      # resolve_conflicts = "OVERWRITE" # <--- REMOVED THIS ARGUMENT
    }
    vpc-cni = {
      most_recent = true
      # resolve_conflicts = "OVERWRITE" # <--- REMOVED THIS ARGUMENT
    }
  } */
  
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_group_defaults = {
    #ami_type = "AL2_x86_64"
    attach_cluster_primary_security_group = true
    enable_cluster_encryption = false
  }

  eks_managed_node_groups = {
    ascode-cluster-wg = {
      min_size     = 0
      max_size     = 1
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      enable_cluster_encryption = false
      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    
    {
      rolearn  = var.github_actions_runner_iam_role_arn # <--- CORRECTED THIS LINE
      username = "github-actions-runner" # <--- CORRECTED THIS LINE (static string)
      groups   = ["system:masters"]
    }
  ]

  tags = local.tags
}

# --- Variables for the root module ---
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster" # This default is overridden by local.name in this config
}

variable "github_actions_runner_iam_role_arn" {
  description = "ARN of the IAM user/role used by GitHub Actions for EKS access"
  type        = string
  default = "arn:aws:iam::593793064016:user/Ammen"
}
