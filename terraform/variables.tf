variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "my-eks-cluster"
}
variable "github_actions_runner_iam_role_arn"
{
  description = "ARN of the IAM role used by GitHub Actions for EKS access"
  default     = "arn:aws:iam::593793064016:user/Ammen" # Replace with your actual role ARN
}
