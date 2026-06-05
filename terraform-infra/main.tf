provider "aws" {
  region                      = var.aws_region # Using our variable!
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  # ADD THESE FOUR LINES HERE TO BYPASS THE TOKEN CHECKS FOR RESOURCES:
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2 = "http://localhost:4566" # Keeps it free and inside MiniStack
    s3       = "http://localhost:4566" # Make sure this is present!
    dynamodb = "http://localhost:4566" 
  }
}

# MNC Standard: The Secure Central Vault for State Storage
resource "aws_s3_bucket" "vprofile_state_vault" {
  bucket = "vprofile-production-state-vault"

  tags = {
    Name        = "State-Vault"
    Environment = "Production-Backend"
  }
}

# MNC Standard: The Concurrency Lock Database
resource "aws_dynamodb_table" "vprofile_state_locks" {
  name         = "vprofile-infrastructure-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID" # This exact string key is required by Terraform!

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Lock-Database"
    Environment = "Production-Backend"
  }
}

resource "aws_vpc" "vprofile_network" {
  cidr_block       = var.vpc_cidr # Using our variable!
  instance_tenancy = "default"

  tags = merge(
    var.project_tags,
    { Name = "vprofile-dynamic-vpc" }
  )
}

resource "aws_subnet" "vprofile_public_subnet" {
  vpc_id            = aws_vpc.vprofile_network.id
  cidr_block        = var.subnet_cidr # Using our variable!
  availability_zone = "${var.aws_region}a"

  tags = merge(
    var.project_tags,
    { Name = "vprofile-dynamic-subnet" }
  )
}

resource "aws_instance" "vprofile_app_server" {
  ami           = "ami-0c55b159cbfafe1f0" # Mock Ubuntu Linux image ID
  instance_type = var.server_type          # Using our new variable!
  subnet_id     = aws_subnet.vprofile_public_subnet.id # Explicit linking!
  source_dest_check = false

  tags = merge(
    var.project_tags,
    { Name = "vprofile-backend-compute" }
  )
}