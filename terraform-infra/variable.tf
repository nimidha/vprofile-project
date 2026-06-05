variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "The target deployment zone"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The base IP range for our enterprise network"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "The IP slice for our public subnet zone"
}

variable "project_tags" {
  type        = map(string)
  default     = {
    Environment = "Local-Sandbox"
    Owner       = "DevOps-Team"
    ManagedBy   = "Terraform"
  }
}

variable "server_type" {
  type        = string
  default     = "t3.micro"
  description = "The hardware size configuration for our application server"
}
