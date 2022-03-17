variable "prefix" {
  type        = string
  description = "Prefix to prepend to all resources"
  default     = "jz"
}

variable "region" {
  type        = string
  description = "Region to deploy resources in"
  default     = "us-east-1"
}

variable "az_list" {
  type        = list(string)
  description = "List of AZs to deploy in"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IP CIDR Block"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDRs"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnets CIDRs"
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "ami_id" {
  type        = string
  description = "EC2 AMI ID"
  default     = "ami-04505e74c0741db8d"
}