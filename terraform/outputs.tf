output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "vpc_id" { # <--- ENSURE THIS IS PRESENT
  description = "The ID of the VPC created by the module"
  value       = module.vpc.vpc_id
}