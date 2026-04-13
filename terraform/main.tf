terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  instance_name = "helioviewer-${var.deployment_name}"
}

# ── SSH key pair ──────────────────────────────────────────────────────────────

# Generate an Ed25519 key pair
resource "tls_private_key" "helioviewer" {
  algorithm = "ED25519"
}

# Register the public key with AWS
resource "aws_key_pair" "helioviewer" {
  key_name   = "helioviewer-${var.deployment_name}-key"
  public_key = tls_private_key.helioviewer.public_key_openssh
}

# Save the private key locally as helioviewer.pem (chmod 400, never committed)
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.helioviewer.private_key_openssh
  filename        = "${path.module}/helioviewer-${var.deployment_name}.pem"
  file_permission = "0400"
}

# ── AMI ───────────────────────────────────────────────────────────────────────

# Look up the latest Ubuntu 24.04 LTS AMI (Canonical's official images)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "helioviewer" {
  name        = "helioviewer-${var.deployment_name}-sg"
  description = "Helioviewer EC2 security group"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "Helioviewer web client"
    from_port   = var.client_port
    to_port     = var.client_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Helioviewer API"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Helioviewer coordinator"
    from_port   = var.coordinator_port
    to_port     = var.coordinator_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Apache Superset"
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Superset guest token service"
    from_port   = 8087
    to_port     = 8087
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.instance_name
  }
}

resource "aws_instance" "helioviewer" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.helioviewer.key_name
  vpc_security_group_ids = [aws_security_group.helioviewer.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  # Require IMDSv2 (more secure instance metadata access)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = templatefile("${path.module}/bootstrap.sh", {
    git_docker_remote      = var.git_docker_remote
    git_docker_branch      = var.git_docker_branch
    git_api_remote         = var.git_api_remote
    git_api_branch         = var.git_api_branch
    git_helioviewer_remote = var.git_helioviewer_remote
    git_helioviewer_branch = var.git_helioviewer_branch
    api_port               = var.api_port
    client_port            = var.client_port
    coordinator_port       = var.coordinator_port
    database_root_password = var.database_root_password
    hv_db_name             = var.hv_db_name
    hv_db_user             = var.hv_db_user
    hv_db_pass             = var.hv_db_pass
    superset_db_name       = var.superset_db_name
    superset_db_user       = var.superset_db_user
    superset_db_pass       = var.superset_db_pass
    superset_admin_user    = var.superset_admin_user
    superset_admin_pass    = var.superset_admin_pass
    superset_read_user     = var.superset_read_user
    superset_read_pass     = var.superset_read_pass
  })

  tags = {
    Name = local.instance_name
  }
}
