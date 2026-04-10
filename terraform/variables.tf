# ── AWS infrastructure ────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type. The full stack needs significant RAM; t3.xlarge (16 GB) is recommended."
  type        = string
  default     = "t3.xlarge"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "ssh_allowed_cidr" {
  description = "CIDR range allowed to SSH to the instance. Defaults to anywhere; restrict to your IP for better security (e.g. \"203.0.113.5/32\")."
  type        = string
  default     = "0.0.0.0/0"
}

# ── Git remotes and branches ──────────────────────────────────────────────────

variable "git_docker_remote" {
  description = "Git remote URL for the helioviewer.org-docker repository"
  type        = string
  default     = "https://github.com/helioviewer-project/helioviewer.org-docker"
}

variable "git_docker_branch" {
  description = "Branch to check out for the helioviewer.org-docker repository"
  type        = string
  default     = "main"
}

variable "git_api_remote" {
  description = "Git remote URL for the Helioviewer API submodule"
  type        = string
  default     = "https://github.com/helioviewer-project/api"
}

variable "git_api_branch" {
  description = "Branch to check out for the Helioviewer API submodule"
  type        = string
  default     = "main"
}

variable "git_helioviewer_remote" {
  description = "Git remote URL for the helioviewer.org front-end submodule"
  type        = string
  default     = "https://github.com/helioviewer-project/helioviewer.org"
}

variable "git_helioviewer_branch" {
  description = "Branch to check out for the helioviewer.org front-end submodule"
  type        = string
  default     = "main"
}

# ── Service ports ─────────────────────────────────────────────────────────────

variable "api_port" {
  description = "Host port for the Helioviewer API service"
  type        = number
  default     = 8081
}

variable "client_port" {
  description = "Host port for the Helioviewer web client"
  type        = number
  default     = 80
}

variable "coordinator_port" {
  description = "Host port for the Helioviewer coordinator service"
  type        = number
  default     = 8000
}

# ── Database (MariaDB) ────────────────────────────────────────────────────────

variable "database_root_password" {
  description = "MariaDB root password"
  type        = string
  sensitive   = true
}

variable "hv_db_name" {
  description = "Helioviewer MariaDB database name"
  type        = string
  sensitive   = true
  default     = "helioviewer"
}

variable "hv_db_user" {
  description = "Helioviewer MariaDB user"
  type        = string
  sensitive   = true
  default     = "helioviewer"
}

variable "hv_db_pass" {
  description = "Helioviewer MariaDB password"
  type        = string
  sensitive   = true
}

# ── Superset ──────────────────────────────────────────────────────────────────

variable "superset_db_name" {
  description = "PostgreSQL database name for Superset metadata"
  type        = string
  sensitive   = true
  default     = "superset"
}

variable "superset_db_user" {
  description = "PostgreSQL user for Superset metadata"
  type        = string
  sensitive   = true
  default     = "superset"
}

variable "superset_db_pass" {
  description = "PostgreSQL password for Superset metadata"
  type        = string
  sensitive   = true
}

variable "superset_admin_user" {
  description = "Superset admin username"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "superset_admin_pass" {
  description = "Superset admin password"
  type        = string
  sensitive   = true
}

variable "superset_read_user" {
  description = "MariaDB read-only user created for Superset to query Helioviewer data"
  type        = string
  sensitive   = true
  default     = "readonly"
}

variable "superset_read_pass" {
  description = "Password for the Superset read-only MariaDB user"
  type        = string
  sensitive   = true
}
