# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module - Using official AWS VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # Public subnets for ALB and NAT gateways
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),  # 10.0.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2),  # 10.0.2.0/24
    cidrsubnet(var.vpc_cidr, 8, 3),  # 10.0.3.0/24
  ]

  # Private subnets for EKS nodes and pods
  private_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 11), # 10.0.11.0/24
    cidrsubnet(var.vpc_cidr, 8, 12), # 10.0.12.0/24
    cidrsubnet(var.vpc_cidr, 8, 13), # 10.0.13.0/24
  ]

  # Enable NAT Gateway for private subnets
  enable_nat_gateway   = true
  single_nat_gateway   = false  # One NAT per AZ for high availability
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                = "1"
    "kubernetes.io/cluster/${var.cluster_name}"            = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}"            = "shared"
    "karpenter.sh/discovery"                                = var.cluster_name
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.vpc_name
    }
  )
}
