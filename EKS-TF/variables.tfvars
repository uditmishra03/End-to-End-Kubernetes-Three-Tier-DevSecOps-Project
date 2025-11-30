# AWS Configuration
aws_region     = "us-east-1"
cluster_name   = "Three-Tier-K8s-EKS-Cluster"
cluster_version = "1.32"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
vpc_name = "three-tier-eks-vpc"

# Node Group Configuration
node_group_name      = "three-tier-node-group"
node_instance_types  = ["t2.medium"]
node_desired_size    = 2
node_min_size        = 2
node_max_size        = 3
node_disk_size       = 20

# Feature Flags
enable_irsa                      = true
enable_load_balancer_controller  = true
enable_ebs_csi_driver            = true

# Environment
environment = "production"

# Tags
tags = {
  Project     = "Three-Tier-DevSecOps"
  ManagedBy   = "Terraform"
  Environment = "production"
  Owner       = "DevSecOps-Team"
}
