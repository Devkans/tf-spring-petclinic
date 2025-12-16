variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-central2"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "europe-central2-a"
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
  default     = "petclinic"
}
