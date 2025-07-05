variable "cluster_name" {} # <--- This line was added to declare the variable

resource "aws_vpc" "main" {
  cidr_block          = "10.0.0.0/16"
  enable_dns_support  = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
    # This tag is crucial for EKS to auto-discover the VPC
    # The value "owned" signifies that EKS fully manages resources within this VPC.
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Internet Gateway for public subnet outbound traffic
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "eks-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "eks-public-rt"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Nodes in this subnet will get public IPs
  tags = {
    Name = "eks-subnet-az1"
    # This tag is crucial for EKS to auto-discover the subnet
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    # This tag is for AWS Load Balancer Controller to find public subnets for ELBs/ALBs
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table_association" "public_subnet1_assoc" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true # Nodes in this subnet will get public IPs
  tags = {
    Name = "eks-subnet-az2"
    # This tag is crucial for EKS to auto-discover the subnet
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    # This tag is for AWS Load Balancer Controller to find public subnets for ELBs/ALBs
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table_association" "public_subnet2_assoc" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}
