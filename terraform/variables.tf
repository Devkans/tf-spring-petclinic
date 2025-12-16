variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_account" {
  description = "Service account email for VM"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "network" {
  description = "VPC network name"
  type        = string
  default     = "arpetclinic-vpc"
}

variable "subnet" {
  description = "Subnet name"
  type        = string
  default     = "arpetclinic-subnet"
}

variable "vm" {
  description = "VM name"
  type        = string
  default     = "arpetclinic-vm"
}

variable "ip" {
  description = "External IP name"
  type        = string
  default     = "arpetclinic-ip"
}

variable "port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "repo" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "arpetclinic-repo"
}

# Database variables
variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}
